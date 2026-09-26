New-Alias which get-command

New-Alias lg lazygit

function goDevelopment {
    if ($WORKSPACE) {
        Set-Location -Path $WORKSPACE
    } else {
        Write-Warning "`$WORKSPACE is not defined"
    }
}
