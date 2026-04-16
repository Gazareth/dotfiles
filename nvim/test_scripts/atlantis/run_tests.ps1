# Run Atlantis Plenary specs (paths relative to this script).
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$testScriptsRoot = Split-Path $scriptDir
$nvimRoot = Split-Path $testScriptsRoot
$testsDir = Join-Path $nvimRoot "nvChad\starter\lua\configs\hydra\atlantis\tests"
$init = Join-Path $testsDir "test_init.lua"
$summaryLua = Join-Path $testScriptsRoot "summarize_plenary_output.lua"

if (-not (Test-Path $init)) {
  Write-Error "test_init.lua not found at: $init"
}

if (-not (Test-Path $summaryLua)) {
  Write-Error "summarize_plenary_output.lua not found at: $summaryLua"
}

if (-not $env:PLENARY_DIR) {
  $lazy = Join-Path $env:LOCALAPPDATA "nvim-data\lazy\plenary.nvim"
  if (Test-Path $lazy) {
    $env:PLENARY_DIR = $lazy
  }
}

$testsLua = ($testsDir -replace "\\", "/")
$initLua = ($init -replace "\\", "/")

$nvim = (Get-Command nvim -ErrorAction Stop).Source
$tmp = [System.IO.Path]::GetTempFileName()
try {
  $output = & $nvim --headless -u $init `
    -c "lua require('plenary.test_harness').test_directory([[$testsLua]], { minimal_init = [[$initLua]] })" `
    -c "qa!" 2>&1 | Out-String
  $exit = $LASTEXITCODE

  Write-Host $output
  [System.IO.File]::WriteAllText($tmp, $output, [System.Text.UTF8Encoding]::new($false))

  & $nvim --headless -u NONE -l $summaryLua -- "$tmp" "Atlantis"
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}

exit $exit
