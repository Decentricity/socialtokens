#!/bin/bash

# Check if near-cli is installed, if not then install it
if ! command -v near &> /dev/null
then
    echo "near-cli could not be found, installing it now..."
    npm install -g near-cli
fi

# Check if user is logged in NEAR CLI
if ! near state $(near whoami | awk '{print $1}') > /dev/null 2>&1
then
    echo "Please login to NEAR CLI first"
    near login
    exit 1
fi

# Check if FT repo exists
if [ ! -d "FT" ]; then
    # Clone the FT repository
    git clone https://github.com/near-examples/FT.git

    # Change directory to FT
    cd FT
else
    # If repo exists, just navigate to it
    cd FT
fi

# Get current logged in NEAR account
ACCOUNT_ID=$(near whoami | awk '{print $1}')

# Sub-account creation
SUB_ACCOUNT=myriad.$ACCOUNT_ID
near create-account $SUB_ACCOUNT --masterAccount $ACCOUNT_ID --initialBalance 1

# Build the fungible token contract
./scripts/build.sh

# Deploy the fungible token contract to the sub-account
near deploy --wasmFile res/fungible_token.wasm --accountId $SUB_ACCOUNT

# Metadata for the fungible token
TOKEN_NAME="Token of $ACCOUNT_ID"
TOKEN_SYMBOL=$(echo ${ACCOUNT_ID:0:5} | awk '{print toupper($0)}')
TOTAL_SUPPLY="100000000"
DECIMALS=8
SPEC="ft-1.0.0"

# Initialize the fungible token contract
near call $SUB_ACCOUNT new '{"owner_id": "'$SUB_ACCOUNT'", "total_supply": "'$TOTAL_SUPPLY'", "metadata": { "spec": "'$SPEC'", "name": "'$TOKEN_NAME'", "symbol": "'$TOKEN_SYMBOL'", "decimals": '$DECIMALS' }}' --accountId $SUB_ACCOUNT

echo "Fungible Token '$TOKEN_NAME' has been deployed and initialized by sub-account '$SUB_ACCOUNT'"
echo "Sub-account '$SUB_ACCOUNT' has been created under '$ACCOUNT_ID'"

# Move back to original directory
cd ..
