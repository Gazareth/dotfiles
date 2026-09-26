$templatePath = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.template.ps1"

function Run-Setup {
    if (Test-Path $PROFILE) {
        $content = Get-Content $PROFILE -Raw
        $match = [regex]::Match($content, '(?i)\$WORKSPACE\s*=\s*''([^'']+)''')
        if ($match.Success) {
            $existingPath = $match.Groups[1].Value
            Write-Host "Profile already exists. Workspace is currently set to: $existingPath"
            $choice = Read-Host "Do you agree to keep this workspace path? (y/n)"
            if ($choice -match '^n') {
                Remove-Item $PROFILE -Force
                Write-Host "Removed existing profile."
                Run-Setup
                return
            } else {
                Write-Host "Setup complete. No changes made."
                return
            }
        } else {
            Write-Host "Profile exists but `$WORKSPACE variable was not found."
            $choice = Read-Host "Do you want to overwrite the existing profile? (y/n)"
            if ($choice -match '^y') {
                Remove-Item $PROFILE -Force
                Run-Setup
                return
            } else {
                Write-Host "Aborted."
                return
            }
        }
    }

    $workspacePath = Read-Host "Please enter the location of your workspace path"
    if ([string]::IsNullOrWhiteSpace($workspacePath)) {
        Write-Host "Workspace path cannot be empty." -ForegroundColor Red
        return
    }

    $templateContent = Get-Content $templatePath -Raw
    $newContent = $templateContent.Replace('{{WORKSPACE_DIR}}', $workspacePath)
    
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    Set-Content -Path $PROFILE -Value $newContent
    Write-Host "PowerShell profile successfully created at $PROFILE" -ForegroundColor Green
}

Run-Setup
