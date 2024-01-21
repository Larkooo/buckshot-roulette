#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./target/dev/manifest.json | jq -r '.world.address')

export CONTRACT_ADDRESSES=$(cat ./target/dev/manifest.json | jq -r '.contracts[] | .address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS 
echo " "
echo contracts : $CONTRACT_ADDRESSES
echo "---------------------------------------------------------------------------"

# enable system -> component authorizations
COMPONENTS=("Game" "Player", "Round", "GamePlayer" )

for contract in ${CONTRACT_ADDRESSES[@]}; do
    for component in ${COMPONENTS[@]}; do
        sozo auth writer $component $contract --world $WORLD_ADDRESS --rpc-url $RPC_URL
        # time out for 1 second to avoid rate limiting
        sleep 1
    done
    echo $contract
done

echo "Default authorizations have been successfully set."