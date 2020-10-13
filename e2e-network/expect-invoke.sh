#!/bin/sh

cli="$1"
peer="$2"
channel="$3"
chaincode="$4"
command="$5"
expected="$6"

label="Invoke $cli/$peer $command"
echo "[testing] $label"

response="$(
  docker exec -e CORE_PEER_ADDRESS="$peer:7051" "$cli" peer chaincode invoke \
    -C "$channel" \
    -n "$chaincode" \
    -c "$command" \
    --waitForEvent \
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "[ok] $label"
else
  echo "[failed] $label | expected: $expected"
  exit 1
fi
