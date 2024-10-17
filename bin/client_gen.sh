#!/bin/bash

rm -rf sdk/src/_generated/_dependencies/*
rm -rf sdk/src/_generated/_framework/*
rm -rf sdk/src/_generated/slamm/*
rm -rf sdk/src/_generated/.eslintrc.json

cd sdk/src/_generated

sui-client-gen
