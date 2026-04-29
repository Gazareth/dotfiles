$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "Building release..."
& cargo build --release --manifest-path "$Root/Cargo.toml"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item "$Root/target/release/atlantis_surveyor.dll" "$Root/lua/native/atlantis_surveyor.dll" -Force

$NvimTs = "$env:LOCALAPPDATA\nvim-configs\default-data\lazy\nvim-treesitter" -replace '\\', '/'
$LuaParser = "$NvimTs/parser/lua.so"
$RootFwd = $Root -replace '\\', '/'

# Write a temp setup file to avoid shell-quoting issues with Windows paths in -c args
$SetupFile = [System.IO.Path]::GetTempFileName() -replace '\\', '/' -replace '\.tmp$', '.lua'
Set-Content -Path $SetupFile -Encoding UTF8 -Value @"
if vim.fn.filereadable('$LuaParser') == 1 then
  vim.treesitter.language.add('lua', { path = '$LuaParser' })
end
"@

Write-Host "Running tests..."
& nvim --headless `
       -u NONE `
       -c "set runtimepath+=$RootFwd" `
       -c "luafile $SetupFile" `
       -c "luafile $RootFwd/tests/test_surveyor.lua" `
       -c "qall!"

Remove-Item $SetupFile -ErrorAction SilentlyContinue

exit $LASTEXITCODE
