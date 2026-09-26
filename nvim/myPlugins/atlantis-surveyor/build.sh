#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
cargo build --release
mkdir -p lua/native
if [[ "$(uname -s)" == "Darwin" ]]; then
  cp "target/release/libatlantis_surveyor.dylib" "lua/native/atlantis_surveyor.so"
else
  cp "target/release/libatlantis_surveyor.so" "lua/native/atlantis_surveyor.so"
fi
echo "Built and copied to lua/native/atlantis_surveyor.so"
