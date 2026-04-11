# atlantis.nvim Context Semantics

Plugin-level context behavior for atlantis.nvim.

Tree-sitter parsing semantics (node tiers and node kinds) are documented in [treesitter/README.md](treesitter/README.md). Probe modules (per node kind) are summarized in [anchor/probe/README.md](anchor/probe/README.md).

## 1. Context Navigation

atlantis.nvim supports the following context selection modes:

Overlapping Tree-sitter nodes are treated as separate anchors. Context navigation picks one anchor at a time, and mode selection controls how you move between those anchors.

- standard: select the intuitive actionable anchor for the current edit intent
- depth_N: select by anchor depth from the highest actionable anchor
- max: select the deepest actionable anchor (closest to cursor)

Depth mode contract:

- depth_0: highest actionable anchor
- depth_1: one step below highest
- depth_2+: continue stepping downward toward cursor

Notes:

- standard is heuristic and can prefer assignment over call inside Habitat
- max is equivalent to the previous lowest-node behavior

## 2. Edge-Case Policy

- Anonymous tokens (actionable): Coral or Chambers (role-dependent)
- Anonymous tokens (non-actionable): Reef, then resolve to nearest actionable anchor
- Comments: actionable Reef (maintenance/preparation actions)
- Strings: typically Chambers when participating in expression/statement semantics
- No node under cursor: provide neighboring-node context and jump options
- Unresolved/uncaught state: show explicit "could not action current cursor position" message
- Multi-cursor: unsupported; show "please exit multi-cursor mode"

## 3. Lua Reference Behavior

Cursor on then inside an if statement:

- local mapping: Coral + kind=keyword
- anchor behavior: defer actions to enclosing conditional frame
- mode effect (standard): intuitive actionable anchor
- mode effect (max): deepest actionable anchor

## 4. Code Separation

Keep modules isolated by responsibility:

- `schema/languages`: raw Tree-sitter node type -> tier/kind/actionable (per language + shared tables)
- `schema/constants`: shared tier/kind ids, probe routing tables
- `schema/actions`: package root — `init.lua` merges **`anchor/`** (per–anchor-kind action allowlists) and **`menu/`** (Hydra row `key`/`icon`/`label`, plus `default_action_order`). Tables only; no application logic in this package.
- `anchor/`: mode-aware anchor selection, probe → parsed payload, jump section data (`anchor/languages` consumes language schema)
- `ops/`: executable behavior — `ops/resolver.lua` loads `ops/actions/common/<action>` and `ops/actions/specific/<action>`, then an optional `<anchor_kind>` module suffix before the base package
- `menu/`: `render_spec` (title + rows), `components/action/order.lua` (stable ordering from allowlist + `default_action_order`), `renderer.lua`, Hydra layout assembly

Allowlists and Hydra row copy live under `schema/actions`; executable actions are wired through `anchor/actions` and `ops/resolver`.

### 4.1 Runtime flow (summary)

Hydra entry (`configs/hydra/init.lua`) → `anchor/build` → `menu/layout.from_context` → `menu/create_hint_menu.create_hint_menu` → `menu/render_spec` builds rows using schema + `anchor/actions.build` for each closure → `lib/make_hydra` + nvim-hydra.

### 4.2 Adding an action

1. Turn the action on for the right anchor kinds in `schema/actions/anchor/init.lua`.
2. Add row metadata (and `default_action_order` if it should appear in the primary block) in `schema/actions/menu/init.lua`.
3. Provide implementation modules under `ops/actions/` so the resolver can find `build(ctx, anchor_kind)`.

This is the baseline contract for extracting these semantics into atlantis.nvim.
