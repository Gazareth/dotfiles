#!/usr/bin/env bash
# Run Atlantis Plenary specs (paths relative to this script).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NVIM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_DIR="$NVIM_ROOT/nvChad/starter/lua/configs/hydra/atlantis/tests"
INIT="$TESTS_DIR/test_init.lua"
SUMMARY_LUA="$TEST_SCRIPTS_ROOT/summarize_plenary_output.lua"

if [[ ! -f "$INIT" ]]; then
  echo "test_init.lua not found at: $INIT" >&2
  exit 1
fi

if [[ ! -f "$SUMMARY_LUA" ]]; then
  echo "summarize_plenary_output.lua not found at: $SUMMARY_LUA" >&2
  exit 1
fi

if [[ -z "${PLENARY_DIR:-}" ]]; then
  lazy="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/plenary.nvim"
  if [[ -d "$lazy" ]]; then
    export PLENARY_DIR="$lazy"
  fi
fi

TESTS_LUA="${TESTS_DIR//\\//}"
INIT_LUA="${INIT//\\//}"

tmp="$(mktemp "${TMPDIR:-/tmp}/atlantis_plenary_out.XXXXXX")"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

set +e
nvim --headless -u "$INIT" \
  -c "lua require('plenary.test_harness').test_directory([[$TESTS_LUA]], { minimal_init = [[$INIT_LUA]] })" \
  -c "qa!" 2>&1 | tee "$tmp"
code=$?
set -e

nvim --headless -u NONE -l "$SUMMARY_LUA" -- "$tmp" "Atlantis"

exit "$code"
