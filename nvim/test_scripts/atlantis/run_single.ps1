# Run a single test file
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$nvimRoot = Split-Path (Split-Path $scriptDir)
$testsDir = Join-Path $nvimRoot "nvChad\starter\lua\configs\hydra\atlantis\tests"
$init = Join-Path $testsDir "test_init.lua"
$testFile = Join-Path $testsDir "menu_resolution\standard_mode\navigate\sibling.lua"

$testFileLua = ($testFile -replace "\\", "/")
$initLua = ($init -replace "\\", "/")

$nvim = (Get-Command nvim -ErrorAction Stop).Source
$output = & $nvim --headless -u $init `
  -c "lua require('plenary.busted').run([[$testFileLua]])" `
  -c "qa!" 2>&1 | Out-String

Write-Host $output
