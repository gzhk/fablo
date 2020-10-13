#!/bin/sh

TEST_TMP="$(mkdir -p "$0.tmpdir" && (cd "$0.tmpdir" && pwd))"
TEST_LOGS="$(mkdir -p "$0.logs" && (cd "$0.logs" && pwd))"
FABRIKKA_HOME="$TEST_TMP/../.."

CONFIG="$FABRIKKA_HOME/samples/fabrikkaConfig-1org-1channel-1chaincode.json"
CHAINCODE="$FABRIKKA_HOME/samples/chaincode-kv-node"

networkUpAsync() {
  (sh "$FABRIKKA_HOME/fabrikka.sh" "$CONFIG" "$TEST_TMP" &&
    cd "$TEST_TMP" &&
    cp -R "$CHAINCODE" "$TEST_TMP" &&
    (sh ./fabrikka-docker.sh up &))
}

dumpLogs() {
  echo "Saving logs of $1 to $TEST_LOGS/$1.log"
  mkdir -p "$TEST_LOGS" &&
    docker logs "$1" >"$TEST_LOGS/$1.log" 2>&1
}

networkDown() {
  rm -rf "$TEST_TEST_LOGS" &&
    dumpLogs "ca.root.com" &&
    dumpLogs "orderer0.root.com" &&
    dumpLogs "ca.org1.com" &&
    dumpLogs "peer0.org1.com" &&
    dumpLogs "peer1.org1.com" &&
    dumpLogs "cli.org1.com" &&
    (cd "$TEST_TMP" && sh ./fabrikka-docker.sh down)
}

waitForContainer() {
  sh "$TEST_TMP/../wait-for-container.sh" "$1" "$2"
}

waitForChaincode() {
  sh "$TEST_TMP/../wait-for-chaincode.sh" "$1" "$2" "$3" "$4" "$5"
}

networkUpAsync

waitForContainer "ca.root.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "orderer0.root.com" "Created and starting new chain my-channel1" &&
  waitForContainer "ca.org1.com" "Listening on http://0.0.0.0:7054" &&
  waitForContainer "peer0.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitForContainer "peer1.org1.com" "Elected as a leader, starting delivery service for channel my-channel1" &&
  waitForChaincode "cli.org1.com" "peer0.org1.com" "my-channel1" "chaincode1" "0.0.1" &&
  waitForChaincode "cli.org1.com" "peer1.org1.com" "my-channel1" "chaincode1" "0.0.1" &&
  networkDown || (networkDown && exit 1)
