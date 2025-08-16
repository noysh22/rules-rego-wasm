#!/usr/bin/env bash

set -euo pipefail

# Script to compile Rego files to WASM using OPA
# Usage: ./rego-to-wasm.sh <opa_path> <input_rego_file> <output_wasm_file> <output_bundle_file>

if [ $# -ne 4 ]; then
    echo "Usage: $0 <opa_path> <input_rego_file> <output_wasm_file> <output_bundle_file>"
    exit 1
fi

OPA_PATH="$1"
INPUT_FILE="$2"
WASM_OUTPUT="$3"
BUNDLE_OUTPUT="$4"

# Define the bundle file name based on the input rego file
BUNDLE_FILE="${INPUT_FILE%.rego}.tar.gz"

# Check if the provided OPA binary exists
if [ ! -f "$OPA_PATH" ]; then
    echo "Error: OPA binary not found at $OPA_PATH"
    exit 1
fi

# Compile Rego to WASM bundle using the provided OPA binary
echo "Compiling $INPUT_FILE to bundle using OPA at $OPA_PATH"
"$OPA_PATH" build -t wasm -e rego/allow "$INPUT_FILE" -o "$BUNDLE_FILE"

# Extract the wasm from the bundle using tar
echo "Extracting wasm from bundle"
tar -xzf "$BUNDLE_FILE"

# Find the wasm file and copy it to the desired output name
WASM_FILE=$(find . -name "*.wasm" | head -1)
if [ -z "$WASM_FILE" ]; then
    echo "Error: No wasm file found in bundle"
    exit 1
fi

# Copy the wasm file to the output location
echo "Copying $WASM_FILE to $WASM_OUTPUT"
cp "$WASM_FILE" "$WASM_OUTPUT"

# Copy the bundle to the output location
echo "Copying bundle to $BUNDLE_OUTPUT"
cp "$BUNDLE_FILE" "$BUNDLE_OUTPUT"

echo "Successfully compiled $INPUT_FILE and created both $WASM_OUTPUT and $BUNDLE_OUTPUT"
