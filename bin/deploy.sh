#!/bin/bash
trap 'echo "Error at line $LINENO: $(caller) -> Command [$BASH_COMMAND] failed with exit code $?" >&2; exit 1' ERR
set -eE


cd contracts/steamm
STEAMM_RESPONSE=$(sui client publish --silence-warnings --no-lint --json)
# STEAMM_RESPONSE=$(cat steamm.json)

find_object_id() {
    local json_content="$1"
    local regex_pattern="$2"

    # Extract objectChanges array from the JSON file
    OBJECTS=$(echo "$json_content" | jq -r ".objectChanges[] | select(.objectType?)")

    # Use the provided regex pattern to filter objects
    RESULT=$(echo "$OBJECTS" | jq -r --arg regex "$regex_pattern" 'select(.objectType | test($regex)) | .objectId')

    if [ -n "$RESULT" ]; then
        echo "$RESULT"
    else
        echo "$regex_pattern not found" >&2
        return 1
    fi
}

registry=$(find_object_id "$STEAMM_RESPONSE" ".*::registry::Registry")
echo "registry: $registry"

lp_metadata=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::CoinMetadata<.*::lp_usdc_sui::LP_USDC_SUI>")
echo "lp_metadata: $lp_metadata"

lp_treasury_cap=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::TreasuryCap<.*::lp_usdc_sui::LP_USDC_SUI>")
echo "lp_treasury_cap: $lp_treasury_cap"

usdc_metadata=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::CoinMetadata<.*::usdc::USDC>")
echo "usdc_metadata: $usdc_metadata"

sui_metadata=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::CoinMetadata<.*::sui::SUI>")
echo "sui_metadata: $sui_metadata"

b_usdc_metadata=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::CoinMetadata<.*::b_usdc::B_USDC>")
echo "b_usdc_metadata: $b_usdc_metadata"

b_sui_metadata=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::CoinMetadata<.*::b_sui::B_SUI>")
echo "b_sui_metadata: $b_sui_metadata"

b_usdc_treasury_cap=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::TreasuryCap<.*::b_usdc::B_USDC>")
echo "b_usdc_treasury_cap: $b_usdc_treasury_cap"

b_sui_treasury_cap=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::TreasuryCap<.*::b_sui::B_SUI>")
echo "b_sui_treasury_cap: $b_sui_treasury_cap"

sui_treasury_cap=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::TreasuryCap<.*::sui::SUI>")
echo "sui_treasury_cap: $sui_treasury_cap"

usdc_treasury_cap=$(find_object_id "$STEAMM_RESPONSE" "0x2::coin::TreasuryCap<.*::usdc::USDC>")
echo "usdc_treasury_cap: $usdc_treasury_cap"

PACKAGE_ID=$(echo "$STEAMM_RESPONSE" | grep -A 3 '"type": "published"' | grep "packageId" | cut -d'"' -f4)
echo "PACKAGE_ID: $PACKAGE_ID"

LENDING_MARKET_REGISTRY="0x4b7912ba1d96ec95954683e0ee94e6d95f511d8be2af88017ffeaff0bd56e422"

SETUP_RESPONSE=$(sui client call --package "$PACKAGE_ID" --module setup --function setup --args "$LENDING_MARKET_REGISTRY" "$registry" "$lp_metadata" "$lp_treasury_cap" "$usdc_metadata" "$sui_metadata" "$b_usdc_metadata" "$b_sui_metadata" "$b_usdc_treasury_cap" "$b_sui_treasury_cap" --json)
# SETUP_RESPONSE=$(cat setup.json)

pool=$(find_object_id "$SETUP_RESPONSE" "${PACKAGE_ID}::pool::Pool<.*>")
echo "Pool: $pool"

sui_bank=$(find_object_id "$SETUP_RESPONSE" "${PACKAGE_ID}::bank::Bank<.*, ${PACKAGE_ID}::sui::SUI, .*>")
echo "SUI Bank: $sui_bank"

usdc_bank=$(find_object_id "$SETUP_RESPONSE" "${PACKAGE_ID}::bank::Bank<.*, ${PACKAGE_ID}::usdc::USDC, .*>")
echo "USDC Bank: $usdc_bank"

lending_market=$(find_object_id "$SETUP_RESPONSE" ".*::lending_market::LendingMarket<.*>")
echo "Lending Market: $lending_market"


#Faucet
SUI_FAUCET_RESPONSE=$(sui client call --package "$PACKAGE_ID" --module faucets --function new --type-args "$PACKAGE_ID"::sui::SUI --args "$sui_treasury_cap" --json)
sui_faucet=$(find_object_id "$SUI_FAUCET_RESPONSE" "${PACKAGE_ID}::faucets::Faucet<.*>")
echo "Sui Faucet: $sui_faucet"

USDC_FAUCET_RESPONSE=$(sui client call --package "$PACKAGE_ID" --module faucets --function new --type-args "$PACKAGE_ID"::usdc::USDC --args "$usdc_treasury_cap" --json)
usdc_faucet=$(find_object_id "$USDC_FAUCET_RESPONSE" "${PACKAGE_ID}::faucets::Faucet<.*>")
echo "USDC Faucet: $usdc_faucet"