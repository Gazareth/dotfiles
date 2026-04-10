# atlantis.nvim Context Semantics

Plugin-level context behavior for atlantis.nvim.

Tree-sitter parsing semantics (node tiers and node kinds) are documented in [treesitter/README.md](treesitter/README.md).

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
- `schema/constants`: shared tier/kind ids, action ids, probe routing tables
- `schema/actions`: allowed action names by resolved anchor kind
- anchor resolver: mode-aware anchor selection (uses language schema via `anchor/languages`)
- ops resolver: resolve each action name to specific/common executable action code
- menu renderer: render and dispatch only; no anchor policy decisions

This is the baseline contract for extracting these semantics into atlantis.nvim.
