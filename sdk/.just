#
# `$ just sui`
#

# By default just list all available commands
[private]
default:
    @just -l sdk

# Regenerates the smart contract bindings
bind:
    rm -rf src/_codegen/_generated/_dependencies/*
    rm -rf src/_codegen/_generated/_framework/*
    rm -rf src/_codegen/_generated/slamm/*
    rm -rf src/_codegen/_generated/.eslintrc.json

    sui-client-gen --manifest src/_codegen/_generated --out src/_codegen/_generated
