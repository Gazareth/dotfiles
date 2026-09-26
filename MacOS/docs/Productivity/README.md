# Productivity tools

### Hammerspoon

Lua scripting for OS tasks (window management, page scrolling, etc.)

https://github.com/hammerspoon/hammerspoon

#### Install (via brew)

```bash
brew install hammerspoon --cask
```
### Config

```bash
ln -s "$DOTFILES_CONFIG_PATH/.hammerspoon" "$HOME/.hammerspoon"
```

### Raycast

Desktop helper (app search, emoji search, snippets, quick links)

https://www.raycast.com/

#### Install (via brew)

```bash
brew install --cask raycast
```

#### Config

Run "Import Settings & Data" using the file from this repo:

`exported/raycast/Raycast 2026-09-23 11.16.03.rayconfig`

### Blink

Instant desktop ("space") switching

https://github.com/benkoppe/Blink

#### Install (via brew)

```bash
brew install --cask benkoppe/tap/blink
```

### Finicky

Customise which browser opens a link based on preconfigured rules

#### Install (via brew)

```bash
brew install --cask finicky
```

### Config

Symbolically link from home to this repo

```bash
ln -s "$DOTFILES_CONFIG_PATH/.finicky.js" "$HOME/.finicky.js"
```
