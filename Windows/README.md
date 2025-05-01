# Windows setup

## Setup

### Add "which" command to powershell

```powershell
"`nNew-Alias which get-command" | add-content $profile
```

If profile has not been created:

```powershell
New-Item -path $PROFILE -type File -force
```

Set workspace root path:

```powershell
"`n`$WORKSPACE = 'X:\Development'" | add-content $profile
```

## Disable Office365 key

Using an elevated shell:

- `REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32`


## Installations

### [Scoop](https://scoop.sh/)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add extras
```

### Lazygit

Install via scoop. Then,

#### Add 'gg' alias

```powershell
"`nNew-Alias gg lazygit" | add-content $profile
```

### Neovim

Install via scoop, then configure.

#### Configure profile

Set env var `NVIM_APPNAME` to whatever you want your profile to be called.

e.g. `NVIM_APPNAME=nvim-configs\default`

##### Create 'junction' between this repo and the nvim config folder

Use [junction](https://superuser.com/a/1020825)

- `cmd /c mklink /j "$ENV:LocalAppData\$ENV:NVIM_APPNAME" "$WORKSPACE\dotfiles\nvim\nvChad\starter"`

#### Install profile dependencies

```powershell
scoop install cmake
```

### [Komorebi](https://github.com/LGUG2Z/komorebi)

Install komorebi as detailed in the readme

#### Create symbolic link to the config file

- `cmd /c mklink "$ENV:UserProfile\komorebi.json" "$WORKSPACE\dotfiles\Windows\config\komorebi.json"`
