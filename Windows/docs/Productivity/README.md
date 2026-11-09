
### Disable Office365 key

Using an elevated shell:

- `REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32`

### [Autohotkey](https://www.autohotkey.com/)

No official programmatic way to install :'(

But make sure to get V2

#### [Komorebi](https://github.com/LGUG2Z/komorebi)

Install komorebi as detailed in the readme

##### Create symbolic link to the config file

- `cmd /c mklink "$ENV:UserProfile\komorebi.json" "$WORKSPACE\dotfiles\Windows\config\komorebi.json"`

### [Talon](https://talonvoice.com/)

Install Talon from the official website. This repository includes [talonhub/community](https://github.com/talonhub/community) as a git submodule under `talon/community` alongside custom commands in `talon/`.

Make sure submodules are initialized (`git submodule update --init --recursive`).

> [!IMPORTANT]
> Talon on Windows ignores `%APPDATA%\talon\user` if it is a symbolic link or directory junction (`mklink /j`). Instead, run a one-time bootstrap copy to `$ENV:AppData\talon\user` — after that, `talon\dotfiles_sync.py` uses Talon's built-in `fs.watch` to automatically sync any edits made in `$WORKSPACE\dotfiles\talon` into `$ENV:AppData\talon\user` in real time.

#### One-time bootstrap to `%APPDATA%\talon\user`

Run `syncTalon` from PowerShell (defined in `Windows\configs\PowerShell\common.ps1`), or manually:

```powershell
robocopy "$WORKSPACE\dotfiles\talon" "$ENV:AppData\talon\user" /MIR /XD .git /XF .dotfiles_source
Set-Content -Path "$ENV:AppData\talon\user\.dotfiles_source" -Value "$WORKSPACE\dotfiles\talon" -NoNewline
```
