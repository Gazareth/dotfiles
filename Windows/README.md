# Windows setup

## Junctions/Symlinks

Use [junction](https://superuser.com/a/1020825)

- `"%AppData%\Local\nvim\lua\custom" to "%ThisRepo%\nvim\lua\custom"


## Disable Office365 key

Using an elevated shell:

- `REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32`

