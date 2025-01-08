#!/bin/bash

# Check if current environment is localnet
INITIAL_ENV=$(sui client envs --json | grep -oE '"[^"]*"' | tail -n1 | tr -d '"')

if [ "$INITIAL_ENV" != "localnet" ]; then
    echo "Current environment is: $INITIAL_ENV. Switching to localnet..."
    sui client switch --env localnet
fi

# Create suilend directory if it doesn't exist and cd into it
mkdir -p temp &&

# Create source directories
mkdir -p temp/liquid_staking/sources temp/pyth/sources temp/sprungsui/sources temp/suilend/sources temp/wormhole/sources temp/steamm/sources

# Copy dependencies from build to local directories
cp -r contracts/steamm/build/steamm/sources/dependencies/liquid_staking/* temp/liquid_staking/sources/
cp -r contracts/steamm/build/steamm/sources/dependencies/Pyth/* temp/pyth/sources/
cp -r contracts/steamm/build/steamm/sources/dependencies/sprungsui/* temp/sprungsui/sources/
cp -r contracts/steamm/build/steamm/sources/dependencies/suilend/* temp/suilend/sources/
cp -r contracts/steamm/build/steamm/sources/dependencies/Wormhole/* temp/wormhole/sources/
cp -r contracts/steamm/sources/* temp/steamm/sources/

# Copy Move.toml files from templates
cp templates/liquid_staking.toml temp/liquid_staking/Move.toml
cp templates/pyth.toml temp/pyth/Move.toml
cp templates/sprungsui.toml temp/sprungsui/Move.toml
cp templates/suilend.toml temp/suilend/Move.toml
cp templates/wormhole.toml temp/wormhole/Move.toml
cp templates/steamm.toml temp/steamm/Move.toml


##### 2. Publish contracts & populate TOMLs ####

# Function to populate TOML file with new address
populate_toml() {
    local NEW_ADDRESS="$1"
    local TOML_PATH="$2"

    # Check if both arguments are provided
    if [ -z "$NEW_ADDRESS" ] || [ -z "$TOML_PATH" ]; then
        echo "Usage: populate_toml <new_address> <path_to_move_toml>"
        ./bin/unpublocal.sh # cleanup
        exit 1
    fi

    # Check if the Move.toml file exists
    if [ ! -f "$TOML_PATH" ]; then
        echo "Error: Move.toml file not found at $TOML_PATH"
        ./bin/unpublocal.sh # cleanup
        exit 1
    fi

    # Use sed to replace any address that equals "0x0" in the [addresses] section
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version
        sed -i '' '/\[addresses\]/,/^$/s/= "0x0"/= "'$NEW_ADDRESS'"/' "$TOML_PATH"
    else
        # Linux version
        sed -i '/\[addresses\]/,/^$/s/= "0x0"/= "'$NEW_ADDRESS'"/' "$TOML_PATH"
    fi

    return 0
}

populate_ts() {
    local PACKAGE_ID="$1"
    local PACKAGE_NAME="$2"
    local TS_FILE="sdk/src/test/packages.ts"

    # Check if TS file exists
    if [ ! -f "$TS_FILE" ]; then
        echo "Error: TypeScript file not found at $TS_FILE"
        ./bin/unpublocal.sh # cleanup
        exit 1
    fi

    # Check if the package constant exists with empty value
    if grep -q "export const $PACKAGE_NAME = \"\";" "$TS_FILE"; then
        # Replace empty value with actual package ID
        sed -i "" "s/export const $PACKAGE_NAME = \"\"/export const $PACKAGE_NAME = \"$PACKAGE_ID\"/;" "$TS_FILE"
    else
        echo "export const $PACKAGE_NAME = \"\";"
        echo "Error: Constant $PACKAGE_NAME not found in $TS_FILE or has unexpected format"
        ./bin/unpublocal.sh # cleanup
        exit 1
    fi
}

publish_package() {
    local FOLDER_NAME="$1"
    local TS_CONST_NAME="$2"
    
    # Check if folder name is provided
    if [ -z "$FOLDER_NAME" ]; then
        echo "Error: Folder name is required"
        ./bin/unpublocal.sh # cleanup
        exit 1
    fi

    # Store current directory
    INITIAL_DIR=$(pwd)
    
    # Change to package directory
    cd "$FOLDER_NAME"
    PACKAGE_ID=$(sui client publish --silence-warnings --no-lint --json --install-dir "$FOLDER_NAME" | grep -A 3 '"type": "published"' | grep "packageId" | cut -d'"' -f4)
    cd "$INITIAL_DIR"

    if [ -z "$PACKAGE_ID" ]; then
        echo "Error: Package ID is empty"
        # ./bin/unpublocal.sh # cleanup
        exit 1
    fi

    echo "Package ID: $PACKAGE_ID"
    populate_toml "$PACKAGE_ID" "$FOLDER_NAME/Move.toml"
    populate_ts "$PACKAGE_ID" "$TS_CONST_NAME"

    return 0
}

publish_package "temp/liquid_staking" "LIQUID_STAKING_PKG_ID"
publish_package "temp/wormhole" "WORMHOLE_PKG_ID"
publish_package "temp/sprungsui" "SPRUNGSUI_PKG_ID"
publish_package "temp/pyth" "PYTH_PKG_ID"
publish_package "temp/suilend" "SUILEND_PKG_ID"
publish_package "temp/steamm" "STEAMM_PKG_ID"


# Reset back to initial environment
if [ "$INITIAL_ENV" != "localnet" ]; then
    echo "Switching back to previous environment"
    sui client switch --env "$INITIAL_ENV"
fi
