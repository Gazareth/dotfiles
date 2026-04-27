# Atlantis Test Scripts

Scripts are located at:
`x:\Development\dotfiles\nvim\test_scripts\atlantis\`

All `<target>` paths are relative to the Atlantis `tests/` root:
`nvChad/starter/lua/configs/hydra/atlantis/tests/`

---

## Run the full test suite

```powershell
x:\Development\dotfiles\nvim\test_scripts\atlantis\run_tests.ps1
```

---

## Run a single file or directory

```powershell
x:\Development\dotfiles\nvim\test_scripts\atlantis\run_single.ps1 <target> [-Filter <pattern>]
```

`<target>` — a `.lua` file or a directory (relative to `tests/`).  
`-Filter` — optional substring matched against each `it(...)` label. Case-sensitive.

### Examples

```powershell
# All sibling tests
x:\Development\dotfiles\nvim\test_scripts\atlantis\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\

# All tests in list.lua
x:\Development\dotfiles\nvim\test_scripts\atlantis\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\list.lua

# Tests whose it-label contains "parameter cursor"
x:\Development\dotfiles\nvim\test_scripts\atlantis\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\list.lua -Filter "parameter cursor"

# Tests whose it-label contains "wrap" anywhere in the sibling suite
x:\Development\dotfiles\nvim\test_scripts\atlantis\run_single.ps1 menu_resolution\standard_mode\navigate\sibling\ -Filter "wrap"
```
