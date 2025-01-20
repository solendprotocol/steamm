#!/bin/bash

# Read the JSON file
json_file="data.json"
json_content=$(cat "$json_file")

# Function to find B_USDC TreasuryCap objectId
find_object_id() {
    local json_content="$1"
    local regex_pattern="$2"
    local b_usdc_treasury_cap

    objects=$(cat "data.json" | jq -r ".objectChanges[] | select(.objectType?)")
    
    result=$(echo "$objects" | jq -r "select(.objectType | test(\"$regex_pattern\")) | .objectId")

    if [ -n "$result" ]; then
        echo "$result"
    else
        echo "$regex_pattern not found" >&2
        return 1
    fi
}

registry=$(find_object_id "$json_content" ".*::registry::Registry")
b_sui_treasury_cap=$(find_object_id "$json_content" "0x2::coin::TreasuryCap<.*::b_sui::B_SUI>")
sui_treasury_cap=$(find_object_id "$json_content" "0x2::coin::TreasuryCap<.*::sui::SUI>")
usdc_treasury_cap=$(find_object_id "$json_content" "0x2::coin::TreasuryCap<.*::usdc::USDC>")
b_usdc_treasury_cap=$(find_object_id "$json_content" "0x2::coin::TreasuryCap<.*::b_usdc::B_USDC>")
lp_treasury_cap=$(find_object_id "$json_content" "0x2::coin::TreasuryCap<.*::lp_usdc_sui::LP_USDC_SUI>")

echo "Registry objectId: $registry"
echo "B_SUI TreasuryCap objectId: $b_sui_treasury_cap"
echo "SUI TreasuryCap objectId: $sui_treasury_cap"
echo "B_USDC TreasuryCap objectId: $b_usdc_treasury_cap"
echo "USDC TreasuryCap objectId: $usdc_treasury_cap"
echo "LP_USDC_SUI TreasuryCap objectId: $lp_treasury_cap"


b_sui_metadata=$(find_object_id "$json_content" "0x2::coin::CoinMetadata<.*::b_sui::B_SUI>")
sui_metadata=$(find_object_id "$json_content" "0x2::coin::CoinMetadata<.*::sui::SUI>")
usdc_metadata=$(find_object_id "$json_content" "0x2::coin::CoinMetadata<.*::usdc::USDC>")
b_usdc_metadata=$(find_object_id "$json_content" "0x2::coin::CoinMetadata<.*::b_usdc::B_USDC>")
lp_metadata=$(find_object_id "$json_content" "0x2::coin::CoinMetadata<.*::lp_usdc_sui::LP_USDC_SUI>")

echo "B_SUI Metadata objectId: $b_sui_metadata"
echo "SUI Metadata objectId: $sui_metadata"
echo "B_USDC Metadata objectId: $usdc_metadata"
echo "USDC Metadata objectId: $b_usdc_metadata"
echo "LP_USDC_SUI Metadata objectId: $lp_metadata"

PACKAGE_ID=$(echo "$STEAMM_RESPONSE" | grep -A 3 '"type": "published"' | grep "packageId" | cut -d'"' -f4)
echo "PACKAGE_ID: $PACKAGE_ID"

# sui client call --package <$PKG_ID> --module <setup> --function <setup>