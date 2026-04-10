---
name: atlantis worker
description: Will help build out the Atlantis code interfacer.
argument-hint: The inputs this agent expects, e.g., "a task to implement" or "a question to answer".
# tools: ['vscode', 'execute', 'read', 'agent', 'edit', 'search', 'web', 'todo'] # specify the tools this agent can use. If not set, all enabled tools are allowed.
---

<!-- Tip: Use /create-agent in chat to generate content with agent assistance -->

Atlantis

Atlantis is a neovim plugin I am building that provides menus with contextual actions for code. It is called with a particular depth value, and will then go away and create a menu of actions based on the nodes under the cursor position, selecting the exact node based on the depth, as well as an "anchor" heuristic that identifies nearby "actionable" nodes.

Node-selection

In order to achieve this, it has to parse the code under the cursor, figure out what nodes are there and what their types are, and then use that information to determine what actions to show in the menu.

The depth arg passed in, combined with the parsing & anchor system handle the fact that a cursor is usually within multiple nested nodes, and the user likely wants to see actions for a specific one of those nodes. 

For example, if the cursor is on a function definition's parameters, the user will first & foremost see actions for the closest surrounding function call (default depth). From there, they can choose to go up to the parent function definition, or object, with one keypress. If the user initially wanted to modify the function parameter the cursor was on, they would call Atlantis with a depth of 1, which would show them actions for the parameter node instead of the function call. The user can then also go up from there to the function definition or object with keypresses.

Menu system

The menu builds Hydra rows from a render spec (title + row list with closures). It should not embed anchor-selection policy or re-derive which actions are allowed; that belongs in `schema/actions` and `anchor/actions`. The worker keeps menu presentation and ordering logic in `menu/` and declarative tables in `schema/`.

Anchor

The anchor pipeline finds the Treesitter node for the cursor and depth, probes it into a parsed payload, and supplies jump metadata. Which **actions** may appear is defined in `schema/actions/anchor` (per anchor kind); **how** they run is implemented under `ops/actions` and reached through `ops/resolver` and `anchor/actions`.

Actions

Action names are enabled per anchor kind in `schema/actions/anchor`. Row labels and keys live in `schema/actions/menu`. Implementations live under `ops/actions/common/` and `ops/actions/specific/`; the resolver tries a node-kind-specific module when present, then the action’s base package. The worker preserves that split: schema tables stay declarative, `ops` stays behavioral, `menu` stays presentation.

The worker will prefer to split out files if they get too large and cover too many concepts. Opting to have an init.lua central file that just pulls in the various submodules, rather than having one large file with a lot of different logic in it. This will help keep the codebase organized and maintainable as it grows.

Minimalism

The worker will default to simplifying in place before introducing new helpers, layers, or files. If a module has one clear job, it should usually expose that job directly rather than wrapping it in private helper functions that are only called once.

The worker will not create wrapper functions that only forward arguments, rename an obvious call, or split a short linear flow across several local helpers. Those steps should stay inline unless extraction clearly removes duplication or makes a genuinely hard branch easier to understand.

The worker will split files by concept, not by tiny helper category. If understanding one behavior requires jumping through a chain of small files, the code is too fragmented and should be pulled back together.

The worker will remove thin glue modules and legacy abstraction layers when they stop carrying real weight. The goal is not a foundation for future code; the goal is the finished codebase in its leanest readable form.

...

Comments

It will always add a short, plain-worded comment atop functions and code blocks that it creates or edits, describing in simple terms what their purpose is. The comment shouldn't require knowledge of other parts of the code in order to decipher. Function parameters will also follow this rule, they should not be fully contextual. This will help ensure that the code is understandable and maintainable for human developers who are new to the codebase and jumping in anywhere to find out what things do.

Comment quality rules for Atlantis code

- Each comment should explain intent or outcome, not restate the symbol name
- Prefer what it enables in the menu or behavior, not what syntax it uses
- Include key context when useful, like fallback order or scoring rule
- Keep comments short fragments, no full stop
- Avoid vague labels like "X builder", "Y map", "Z helper" unless they include purpose

Bad -> Better examples

- "Count node lines" -> "Count lines spanned by node for title metrics"
- "Lookup merger" -> "Merge callback lookups with extra keys overriding base"
- "Action builder resolver" -> "Resolve node-specific action builder with fallback"
- "Named child list" -> "Collect named children in source order"

When files get too large and cover too many concepts, the agent should split them up into smaller files with focused purposes. For example, the current parameter probe file is quite large and covers a lot of different logic related to parsing parameters, handling edge cases, and building parameter info. This could be split into multiple files.

Perhaps most importantly, don't leave legacy code around. If you change how something works, make sure to remove the old code and comments that are no longer relevant. This will help keep the codebase clean and maintainable as it evolves. This code should be super elegant and lean, with DRY principles followed closely. If you find yourself copying and pasting code, that's a sign that it should be refactored into a reusable function or module. Always look for opportunities to simplify and streamline the code, while still maintaining readability and clarity.