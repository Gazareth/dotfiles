# atlantis_surveyor

Rust **cdylib** for Neovim ([nvim-oxi](https://github.com/noib3/nvim-oxi)) that classifies Tree-sitter nodes and computes navigation targets for the Atlantis UI.

## Requirements

- Neovim **0.11+**
- **Rust** toolchain (`cargo`)
- On **Windows**: PowerShell for `build.ps1`. The crate does **not** enable nvim-oxi's `mlua` feature so the DLL does not pull a second static LuaJIT.

## Build

From this directory:

```bash
./build.sh    # Unix / macOS (copies to lua/native/atlantis_surveyor.so)
```

```powershell
.\build.ps1   # Windows → lua/native/atlantis_surveyor.dll
```

Or manually:

```powershell
cargo build --release
Copy-Item "target/release/atlantis_surveyor.dll" "lua/native/atlantis_surveyor.dll" -Force
```

## Load

- `lua/atlantis_surveyor.lua` calls `package.loadlib` on `lua/native/atlantis_surveyor.{dll,so}`.
- In Neovim: `require("atlantis_surveyor")` returns a callable function.
- The Lua side (`configs/hydra/atlantis_nouveau/`) passes a Tree-sitter ancestry table and receives a `SurveyResult`.

## Layout

```
src/
  lib.rs                        — Plugin entrypoint, exports the surveyor function
  model/
    atlantis_node.rs            — AtlantisNode enum: Recognised / Leaf / Unrecognised
    navigation_target.rs        — NavigationTarget and OutlineItem structs
    node/                       — RawNode, NodeRange, Node<Lang, State>, Extract trait
    supported_nodes/
      standard/                 — Semantic nodes: Function, Assignment, Call, Conditional, Parameter, ReturnStatement
      container/                — Structural groupings: Body, ParameterList, ExpressionList, FileRoot
    lang/
      node_kind.rs              — NodeKind enum and is_transparent() logic
      languages/lua.rs          — Lua language syntax map and custom Extract impls
      macros.rs                 — impl_language_syntax_map! / impl_lang_node_resolver! macros
  probe/
    language.rs                 — Language enum and classify() dispatch
    treesitter/                 — Tree-sitter snapshotting via luaeval
  survey/
    mod.rs                      — SurveyResult: top-level Ok/Err response type
    focused_node/
      mod.rs                    — FocusedNode resolution from ancestry
      ancestry.rs               — NodeAncestry parsing and find_focus_idx()
      navigation/               — NavigationInfo: parent, siblings, body, function targets
      outline.rs                — Outline computation (navigable children of a node)
      actions.rs                — available_actions() dispatch
```

## Node Classification

Every Tree-sitter node is classified into one of three variants:

- **`Recognised`** — A node Atlantis has registered behaviour for (e.g. `function_declaration`, `if_statement`). Carries a fully-resolved language-specific node with extracted state (name, parameters, body, etc.) and an outline of its navigable children.
- **`Leaf`** — An unrecognised token inside a transparent structural grouping (e.g. an `identifier` inside an `expression_list`). Siblings are navigable; no further structure.
- **`Unrecognised`** — Atlantis has no registered behaviour for this node type. The ancestry resolver climbs upward until it reaches a `Recognised` node.

### Transparent nodes

Some `Recognised` nodes are **transparent** during ancestry traversal — the resolver passes through them rather than anchoring on them. These are structural groupings:

| NodeKind        | Example TS kinds             |
|-----------------|------------------------------|
| `Body`          | `block`                      |
| `ParameterList` | `parameters`, `variable_list`|
| `ExpressionList`| `expression_list`, `binary_expression`, `arguments` |
| `FileRoot`      | `chunk`                      |

## Submodule (dotfiles)

To track this as its own Git repo under dotfiles:

```bash
git submodule add https://github.com/<you>/atlantis-surveyor.git nvim/myPlugins/atlantis-surveyor
```

Then point Lazy's `dir` at that path (or switch the spec to the Git URL once published).
