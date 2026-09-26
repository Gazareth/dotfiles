# Development setup

## Lazygit

https://github.com/jesseduffield/lazygit

### Install (via brew)

```bash
brew install lazygit
```

## Neovim + Neovide

### Neovim

"Hyperextensible text editor"

https://neovim.io/doc/install/

#### Install (via brew)

```bash
brew install neovim
```

#### Config

Use [NVIM_APPNAME (Docs)](https://neovim.io/doc/user/starting/#%24NVIM_APPNAME) to run neovim with different 'profiles'

e.g. `NVIM_APPNAME=nvim-configs/default` (this should be set in `~/.zprofile`)

#### Create symlink between this repo and the nvim config folder

> [!NOTE]
> `$HOME/.config` here is trying to predict $XDG_CONFIG_HOME's value. If it is empty, it defaults to $HOME/.config.
> As per [this superuser.com answer](https://superuser.com/a/1930872)

- `ln -s  "$DOTFILES_PATH/nvim/nvChad/starter" "$HOME/.config/$NVIM_APPNAME"`

#### Install profile dependencies

##### Cmake

cmake is required for [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim)

```bash
brew install cmake
```

##### Ripgrep

Ripgrep is required for [grug-far](https://github.com/MagicDuck/grug-far.nvim)

```bash
brew install ripgrep
```

##### Treesitter

`tree-sitter` is required for granular syntax highlighting

```bash
brew install tree-sitter
```

### Neovide

Rust-based graphical renderer for Neovim

neovide.dev

#### Install (via brew)

```bash
brew install neovide
```

### Github CLI (gh)

https://cli.github.com/

#### Install (via brew)

```bash
brew install gh
```
