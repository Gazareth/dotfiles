# atlantis.nvim Context Semantics

Plugin-level context behavior for atlantis.nvim.

Tree-sitter parsing semantics (node tiers and node kinds) are documented in [treesitter/README.md](treesitter/README.md).

## 1. Anchor Modes

atlantis.nvim supports two context selection modes:

- standard context: select eldest valid proximal node
- lowest context: select youngest valid proximal node

This is the tie-break policy when multiple valid anchors are present (for example Chambers and Habitat).

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
- mode effect (standard context): eldest valid anchor
- mode effect (lowest context): youngest valid anchor

## 4. Code Separation

Keep modules isolated by responsibility:

- language mapping: raw Tree-sitter -> tier/kind/actionable candidate
- actionability policy: direct vs deferred action eligibility
- anchor resolver: mode-aware anchor selection
- action generator: user-facing actions from resolved anchor

This is the baseline contract for extracting these semantics into atlantis.nvim.
