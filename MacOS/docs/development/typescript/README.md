# Development setup

## node

https://nodejs.org/en

### Install - nvm (via brew)
brew install nvm

```bash
brew install nvm
```

### Install node (via nvm)

```bash
nvm install 24
```

## mise

https://mise.jdx.dev/installing-mise.html

### Install (via brew)

```bash
brew install mise
```

### Config

Add the mise activation script output to your `.zshrc`

```bash
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

## pnpm

https://pnpm.io/

### Install (via mise - requires `mise.toml` in e.g. repo root)

Go to repo root and run

```bash
mise install
```
