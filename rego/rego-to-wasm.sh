#!/usr/bin/env bash

set -euo pipefail

# Script to compile Rego files to WASM using OPA
# Usage: ./rego-to-wasm.sh <opa_path> <entrypoint> <output_wasm_file> <output_bundle_file> <input_files...>

if [ $# -lt 5 ]; then
    echo "Usage: $0 <opa_path> <entrypoint> <output_wasm_file> <output_bundle_file> <input_files...>" >&2
    exit 1
fi

OPA_PATH="$1"
ENTRYPOINT="$2"
WASM_OUTPUT="$3"
BUNDLE_OUTPUT="$4"
shift 4
INPUT_FILES=("$@")

# Check if the provided OPA binary exists
if [ ! -f "$OPA_PATH" ]; then
    echo "Error: OPA binary not found at $OPA_PATH" >&2
    exit 1
fi

# Ensure there is at least one .rego file
has_rego=0
for f in "${INPUT_FILES[@]}"; do
    if [[ "$f" == *.rego ]]; then
        has_rego=1
        break
    fi
done
if [ "$has_rego" -ne 1 ]; then
    echo "Error: At least one .rego file must be provided among input files." >&2
    exit 1
fi

# Build the bundle directly to the requested bundle output path
# OPA supports including .rego modules and JSON/YAML data files together
INPUT_FILES_STR="${INPUT_FILES[*]}"
echo "Compiling to bundle using OPA at $OPA_PATH (entrypoint: $ENTRYPOINT)"
"$OPA_PATH" build -t wasm -e "$ENTRYPOINT" -o "$BUNDLE_OUTPUT" $INPUT_FILES_STR

# Extract the wasm from the bundle in the current working directory
echo "Extracting wasm from bundle"
tar -xzf "$BUNDLE_OUTPUT"

# Find the wasm file and copy it to the desired output name
WASM_FILE=$(find . -name "*.wasm" | head -1)
if [ -z "$WASM_FILE" ]; then
    echo "Error: No wasm file found in bundle" >&2
    exit 1
fi

echo "Copying $WASM_FILE to $WASM_OUTPUT"
cp "$WASM_FILE" "$WASM_OUTPUT"

echo "Successfully compiled inputs and created both $WASM_OUTPUT and $BUNDLE_OUTPUT"
