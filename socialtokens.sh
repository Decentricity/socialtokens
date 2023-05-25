#!/bin/bash

echo "Checking if near-cli is installed..."
sleep 0.25
if ! command -v near &> /dev/null
then
    echo "near-cli could not be found, installing it now..."
    npm install -g near-cli
fi

echo "Fetching NEAR account from the script parameters..."
sleep 0.25
ACCOUNT_ID=$1

if [ -z "$ACCOUNT_ID" ]; then
    echo "You must provide your NEAR account as an argument."
    exit 1
fi

echo "Checking if FT repo exists..."
sleep 0.25
if [ ! -d "FT" ]; then
    echo "Cloning the FT repository..."
    sleep 0.25
    git clone https://github.com/near-examples/FT.git
    cd FT
else
    echo "FT repo exists, navigating to it..."
    sleep 0.25
    cd FT
fi

echo "Creating sub-account..."
sleep 0.25
SUB_ACCOUNT=myriadsocial.$ACCOUNT_ID
near create-account $SUB_ACCOUNT --masterAccount $ACCOUNT_ID --initialBalance 10

echo "Building the fungible token contract..."
sleep 0.25
./scripts/build.sh

echo "Deploying the fungible token contract to the sub-account..."
sleep 0.25
near deploy --wasmFile res/fungible_token.wasm --accountId $SUB_ACCOUNT

echo "Preparing metadata for the fungible token..."
sleep 0.25
TOKEN_NAME="Token of $ACCOUNT_ID"
TOKEN_SYMBOL=$(echo ${ACCOUNT_ID:0:5} | awk '{print toupper($0)}')
TOTAL_SUPPLY="100000000"
DECIMALS=8
SPEC="ft-1.0.0"

echo "Initializing the fungible token contract..."
sleep 0.25
near call $SUB_ACCOUNT new '{"owner_id": "'$SUB_ACCOUNT'", "total_supply": "'$TOTAL_SUPPLY'", "metadata": { "spec": "'$SPEC'", "name": "'$TOKEN_NAME'", "symbol": "'$TOKEN_SYMBOL'", "decimals": '$DECIMALS' }}' --accountId $SUB_ACCOUNT

echo "Fungible Token '$TOKEN_NAME' has been deployed and initialized by sub-account '$SUB_ACCOUNT'"
echo "Sub-account '$SUB_ACCOUNT' has been created under '$ACCOUNT_ID'"
sleep 0.25

echo "Moving back to original directory..."
sleep 0.25
cd ..
