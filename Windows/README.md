# Windows setup

## Junctions/Symlinks - Neovims

Use [junction](https://superuser.com/a/1020825)

- `mklink /j "%LocalAppData%\nvim\lua" "X:\Development\dotfiles\nvim\nvChad\starter\lua"`
- `mklink /j "%LocalAppData%\nvim\after" "X:\Development\dotfiles\nvim\nvChad\starter\after"`

You must also copy over `init.lua` and `stylua.toml` for NvChad initialization

## Disable Office365 key

Using an elevated shell:

- `REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32`

