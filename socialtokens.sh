#!/bin/bash

# Check if near-cli is installed, if not then install it
if ! command -v near &> /dev/null
then
    echo "near-cli could not be found, installing it now..."
    npm install -g near-cli
fi

# Get the account from the script parameters
ACCOUNT_ID=$1

if [ -z "$ACCOUNT_ID" ]; then
    echo "You must provide your NEAR account as an argument."
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

# Sub-account creation
SUB_ACCOUNT=myriadsocial.$ACCOUNT_ID
near create-account $SUB_ACCOUNT --masterAccount $ACCOUNT_ID --initialBalance 10

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

# Assume 10 tokens are to be sent
TOKENS_TO_SEND=10
RECIPIENT_ID="decentricity.testnet"

# Transfer tokens from the main account to the recipient
near call $SUB_ACCOUNT_ID ft_transfer '{"receiver_id": "'$RECIPIENT_ID'", "amount": "'$TOKENS_TO_SEND'"}' --accountId $NEAR_ACCOUNT_ID --amount 0.000000000000000000000001

echo "Sent $TOKENS_TO_SEND tokens to $RECIPIENT_ID from $SUB_ACCOUNT_ID"


# Move back to original directory
cd ..
