# Windows setup

## Junctions/Symlinks

Use [junction](https://superuser.com/a/1020825)

- `mklink /j "C:\Users\Gareth\AppData\Local\nvim\lua" "X:\Development\dotfiles\nvim\nvChad\starter\lua"`
- `mklink /j "C:\Users\Gareth\AppData\Local\nvim\after" "X:\Development\dotfiles\nvim\nvChad\starter\after"`

Also copy over `init.lua` and `stylua.toml` for NvChad initialization 

## Disable Office365 key

Using an elevated shell:

- `REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32`

