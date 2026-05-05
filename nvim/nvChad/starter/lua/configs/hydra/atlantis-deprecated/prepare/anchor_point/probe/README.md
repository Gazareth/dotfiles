# Probes

Tree-sitter is phenomenal at identifying the syntax tree of your code, but its output is raw, hyper-specific to the programming language, and highly granular. Atlantis needs a uniform way to understand code structure across different languages.

This is where **Probes** come in.

## 1. The Role of a Probe

A probe receives an already-parsed Tree-sitter node. **Probes do not parse text**—that is Tree-sitter's job. Instead, probes act as a translation layer. They inspect the raw node and map it into a standardized **Atlantis Payload**.

This payload extracts consistent, language-agnostic properties (like the name of a function, the targets of an assignment, or the bounds of a block body) so that the Atlantis `menu` and `ops` modules can process them uniformly without caring if the underlying language is Lua, Python, or TypeScript.

## 2. Active Probes

Different semantic kinds of code require different probing strategies. Atlantis routes nodes to the appropriate probe based on their semantic kind.

| Module | What it extracts into the Atlantis Payload |
|---|---|
| `assignment` | Resolves the Left-Hand Side (names being bound) and Right-Hand Side (values). Identifies if the assignment is a local binding. |
| `function` | Extracts the function name and parameter list. Crucially, it isolates the **`body`** node (the block of code inside the function), which is essential for establishing the boundaries of a **Container Anchor**. |
| `binary_expression` | Extracts the specific operator (e.g., `and`, `+`) and the left/right operands. |
| `identifier` | Extracts the bare symbol name and its context for simple identifier nodes. |
| `generic` | The fallback probe. Used when a node is recognized as actionable but doesn't map to a highly specialized shape. Returns minimal role and display information. |
