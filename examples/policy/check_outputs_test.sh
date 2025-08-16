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

for f in "$@"; do
  echo "Checking: $f"
  if [[ "$f" == *.wasm ]]; then
    if [ -s "$f" ]; then
      has_wasm=1
    else
      echo "WASM file is missing or empty: $f" >&2
      exit 1
    fi
  fi
  if [[ "$f" == *_bundle.tar.gz ]]; then
    if [ -s "$f" ]; then
      has_bundle=1
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

echo "Both wasm and bundle outputs exist and are non-empty."

