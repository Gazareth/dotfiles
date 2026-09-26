
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