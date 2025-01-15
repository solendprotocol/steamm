#
# `$ just sui`
#

# By default just list all available commands
[private]
default:
    @just -l sui

# Fails if sui is not a binary
[private]
_check_sui:
    #!/bin/bash
    if ! command -v sui 2>&1 >/dev/null
    then
        echo "sui binary not found"
        echo "You can download the binary from https://github.com/MystenLabs/sui/releases"
        exit 1
    fi

# Builds all things Sui
build: _check_sui
    sui move build -p steamm

# Tests all things Sui
test: _check_sui
    sui move test -p steamm --gas-limit 5000000000000

# Starts a localnet faucet process on port 9123 that airdrops 500 SUI
faucet: _check_sui
    ../sui/sui-faucet --write-ahead-log $HOME/.sui/sui_config/faucet.wal --port 9123 --amount 500000000000

# Resets localnet state and starts the network
localnew: _check_sui
    sui genesis -f
    sui start

# Starts the localnet network
local: _check_sui
    sui start
