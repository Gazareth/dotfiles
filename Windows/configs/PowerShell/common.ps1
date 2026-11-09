New-Alias which get-command

New-Alias lg lazygit

function goDevelopment {
    if ($WORKSPACE) {
        Set-Location -Path $WORKSPACE
    } else {
        Write-Warning "`$WORKSPACE is not defined"
    }
}

function syncTalon {
    $source = Join-Path $DOTFILES_DIR "talon"
    $dest = Join-Path $ENV:AppData "talon\user"

    if (Test-Path $dest) {
        $item = Get-Item $dest -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            cmd /c rmdir "$dest"
        }
    }

    robocopy "$source" "$dest" /MIR /XD .git /XF .dotfiles_source | Out-Host
    Set-Content -Path (Join-Path $dest ".dotfiles_source") -Value $source -NoNewline
    Write-Host "Talon user directory synced from $source to $dest" -ForegroundColor Green
}
