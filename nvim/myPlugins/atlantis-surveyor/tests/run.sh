#!/usr/bin/env bash
set -e
ROOT="$(dirname "$0")/.."

echo "Building release..."
cargo build --release --manifest-path "$ROOT/Cargo.toml"
cp "$ROOT/target/release/libatlantis_surveyor.so" "$ROOT/lua/native/atlantis_surveyor.so"

echo "Running tests..."
nvim --headless \
     -u NONE \
     -c "set runtimepath+=$ROOT" \
     -c "luafile $ROOT/tests/test_surveyor.lua" \
     -c "qall!"
