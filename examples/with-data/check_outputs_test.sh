#!/usr/bin/env bash
set -euo pipefail

# This test verifies that the rego_to_wasm rule produces both a .wasm and a _bundle.tar.gz file.
# It receives the produced files as arguments via $(locations :example_policy).

if [ "$#" -lt 2 ]; then
  echo "Expected at least 2 file paths (wasm and bundle), got $#" >&2
  exit 1
fi

has_wasm=0
has_bundle=0
bundle_file=""
wasm_file=""

for f in "$@"; do
  echo "Checking: $f"
  if [[ "$f" == *.wasm ]]; then
    if [ -s "$f" ]; then
      has_wasm=1
      wasm_file="$f"
    else
      echo "WASM file is missing or empty: $f" >&2
      exit 1
    fi
  fi
  if [[ "$f" == *_bundle.tar.gz ]]; then
    if [ -s "$f" ]; then
      has_bundle=1
      bundle_file="$f"
    else
      echo "Bundle file is missing or empty: $f" >&2
      exit 1
    fi
  fi
done

if [ "$has_wasm" -ne 1 ]; then
  echo "Did not receive a .wasm file in arguments" >&2
  exit 1
fi
if [ "$has_bundle" -ne 1 ]; then
  echo "Did not receive a _bundle.tar.gz file in arguments" >&2
  exit 1
fi

# Verify that the data.json inside the bundle matches the input data.json
# Locate the input data.json in the runfiles (passed via data attr)
input_data_json="examples/with-data/data.json"
if [ ! -f "$input_data_json" ]; then
  # Try to resolve via RUNFILES if needed
  input_data_json=$(pwd)/examples/with-data/data.json
fi

if [ ! -f "$input_data_json" ]; then
  echo "Could not locate input data.json for comparison" >&2
  exit 1
fi

# Extract data.json from the bundle into a temp dir and compare
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

tar -xzf "$bundle_file" -C "$TMPDIR"

# OPA bundles typically put data under data.json at the root
bundle_data_json="$TMPDIR/data.json"

if [ ! -f "$bundle_data_json" ]; then
  echo "data.json not found inside bundle" >&2
  echo "Bundle contents:" >&2
  tar -tzf "$bundle_file" >&2 || true
  exit 1
fi

# Compare content
if ! diff -u "$input_data_json" "$bundle_data_json"; then
  echo "data.json inside bundle does not match source examples/with-data/data.json" >&2
  exit 1
fi

echo "Both wasm and bundle outputs exist and are non-empty."

