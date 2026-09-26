$WORKSPACE = '{{WORKSPACE_DIR}}'
$DOTFILES_DIR = Join-Path $WORKSPACE "dotfiles"

$commonProfilePath = Join-Path $DOTFILES_DIR "Windows\configs\PowerShell\common.ps1"
if (Test-Path $commonProfilePath) {
    . $commonProfilePath
} else {
    Write-Warning "Could not find common dotfiles profile at $commonProfilePath"
}
