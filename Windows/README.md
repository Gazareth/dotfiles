# Windows setup

## Setup

### Create workspace and clone dotfiles

#### Setup PowerShell profile

Run the interactive setup script to generate your PowerShell profile:

```powershell
.\Windows\configs\PowerShell\setup.ps1
```

### Core Apps

#### [Scoop](https://scoop.sh/)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add extras
```

### Other apps

[Productivity](docs/Productivity)

[Development](docs/development)
- [Typescript](docs/development/typescript)
