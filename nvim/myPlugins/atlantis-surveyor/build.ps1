$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
cargo build --release
$dest = Join-Path $PSScriptRoot "lua/native"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $PSScriptRoot "target/release/atlantis_surveyor.dll") (Join-Path $dest "atlantis_surveyor.dll") -Force
Write-Host "Built and copied to lua/native/atlantis_surveyor.dll"
