# Run a single Atlantis test file or directory, with optional name filter.
#
# Usage:
#   .\run_single.ps1 <target> [-Filter <pattern>]
#
# <target>  Path relative to the atlantis tests/ root.
#           A .lua file runs that file; a directory runs all files via its init.lua.
#
# -Filter   Optional substring matched against each test's full name
#           (concatenated describe + it labels). Case-sensitive.
#
# Examples:
#   .\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\list.lua
#   .\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\list.lua -Filter "parameter cursor"
#   .\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\
#   .\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\ -Filter "wrap"

param(
  [Parameter(Mandatory=$true, Position=0)][string]$Target,
  [string]$Filter = ""
)

$ErrorActionPreference = "Stop"
$scriptDir  = $PSScriptRoot
$nvimRoot   = Split-Path (Split-Path $scriptDir)
$testsDir   = Join-Path $nvimRoot "nvChad\starter\lua\configs\hydra\atlantis\tests"
$init       = Join-Path $testsDir "test_init.lua"
$summaryLua = Join-Path (Split-Path $scriptDir) "summarize_plenary_output.lua"

$targetPath = Join-Path $testsDir $Target
if (-not (Test-Path $targetPath)) {
  Write-Error "Target not found: $targetPath"
  exit 1
}

# Derive the Lua module path and a short display name from the target.
$rel = $Target.TrimEnd('\').TrimEnd('/')
if ($rel.EndsWith(".lua")) { $rel = $rel.Substring(0, $rel.Length - 4) }
$modulePath = "configs.hydra.atlantis-deprecated.tests." + ($rel -replace '[/\\]', '.')
$suiteName  = ($rel -replace '[/\\]', ' > ').Split(' > ')[-1]

# Build the spec content. If a filter is given, wrap `it` so only matching
# tests are registered (busted collects tests at describe-time, so this works).
if ($Filter -ne "") {
  $specContent = @"
local _real_it = it
it = function(name, fn, ...)
  -- full name built by busted is describe-label + " " + it-label, but we only
  -- have the it-label here; match against that as a substring.
  if tostring(name):find([[$Filter]], 1, true) then
    _real_it(name, fn, ...)
  end
end
require('$modulePath')()
"@
} else {
  $specContent = "require('$modulePath')()"
}

# Write to a temp dir so test_directory finds exactly one *_spec.lua.
$tempDir  = Join-Path $env:TEMP "atlantis_run_single"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$tempSpec = Join-Path $tempDir "run_single_spec.lua"
[System.IO.File]::WriteAllText($tempSpec, $specContent, [System.Text.UTF8Encoding]::new($false))

$tempDirLua = ($tempDir  -replace "\\", "/")
$initLua    = ($init     -replace "\\", "/")

$nvim = (Get-Command nvim -ErrorAction Stop).Source
$tmp  = [System.IO.Path]::GetTempFileName()
try {
  $output = & $nvim --headless -u $init `
    -c "lua require('plenary.test_harness').test_directory([[$tempDirLua]], { minimal_init = [[$initLua]] })" `
    -c "qa!" 2>&1 | Out-String
  $exit = $LASTEXITCODE

  [System.IO.File]::WriteAllText($tmp, $output, [System.Text.UTF8Encoding]::new($false))
  & $nvim --headless -u NONE -l $summaryLua -- "$tmp" "$suiteName"
} finally {
  Remove-Item -LiteralPath $tmp     -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $tempSpec -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $tempDir  -Force -Recurse -ErrorAction SilentlyContinue
}

exit $exit
