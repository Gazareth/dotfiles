# atlantis.nvim Tree-sitter Semantics

Atlantis uses Tree-sitter to parse node information, then assigns its own meaning and actions to the nodes. This is an abstraction that allows Atlantis to stand a fighting chance in operating across multiple languages.

## Node tiers

Order (largest to least meaningful surface):

1. Colony
	- Meta and top-level containers (class, namespace, module, similar)
2. Settlement
	- Function and method definitions
3. Grove/Cluster
	- Grove: collection groupings (parameter lists, variable lists, argument lists, collection literals)
	- Cluster: control/grouping frames (if/elseif/else, for/while/repeat, switch/match, try/catch, similar)
4. Habitat
	- Executable statements (assignment, call, return, etc.)
5. Chambers
	- Statement components (targets, values, receivers, properties, subexpressions)
6. Coral
	- Smallest meaningful tokens (keyword/operator markers such as then, in)
7. Reef
	- Background syntax and non-semantic surface (spacing, delimiters, separators, trivia)

## Node kinds

These are the main kind groups Atlantis uses when mapping nodes:

- Structural:
	- declaration
	- collection
	- control_frame
- Statement:
	- statement
	- assignment
	- call
- Symbol/reference:
	- identifier
	- property
- Token:
	- keyword
	- operator
	- delimiter
	- whitespace
- Content and diagnostics:
	- comment
	- string
	- error
- Legacy/general kind:
	- control

Language modules map parser node/token types to kind values.
Each Atlantis tier/kind maps one or more raw Tree-sitter node or token names into a consistent cross-language semantic label.
