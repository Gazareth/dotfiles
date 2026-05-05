# Atlantis

Atlantis is a Neovim plugin that provides a highly contextual, AST-driven interaction menu. Powered by Neovim Tree-sitter and Hydra, Atlantis maps out the syntax tree of your code and presents you with dynamic context menus, outlines, and structural navigation tools.

## 1. Core Concepts

At the heart of Atlantis is the distinction between two primary types of contextual scopes:

### Standard Anchors
Standard Anchors represent specific entities in your code, such as a **Function Declaration**, an **Assignment**, or an **Identifier**. 

By default, Atlantis **always** opens in **Standard Mode** at `depth: 0`. At this depth, Atlantis will scan upwards to find the nearest **first class** standard anchor (typically function declarations or major structural statements). 

However, if you want to target a more granular, lower-tier node (like a specific nested parameter or an inner statement), you call Atlantis with `depth: 1`. This loosens the filter, telling Atlantis to scan upwards and **resolve to** the nearest anchor of **any kind**, rather than skipping over them to find a first-class anchor.

### Container Anchors
Container Anchors represent scoped execution blocks, such as the **File Root** or a **Function Body**. Note the distinction: a function *declaration* is a Standard Anchor, but the function's *body* is a Container Anchor.

**Container Mode** is a secondary state that you must explicitly navigate to (e.g., by jumping "to container"). Once in Container Mode, the Interact menu is replaced by the **Outline** menu, acting as a "picker" to list and navigate between all the `Assignments`, `Declarations`, and `Control Flow` statements native to that specific local scope.

## 2. Navigation Engine

The **Navigate** column is present in both modes and provides structural, AST-aware traversal:

- **Context Navigation**: Allows you to step upwards into the parent block or drop downwards into child scopes.
- **Sibling Navigation**: Allows you to jump between adjacent statements (e.g., previous/next assignment or declaration). Sibling navigation respects local scope boundaries—when you reach the end of a local block, the navigation intelligently wraps around ("To first sibling") instead of blindly climbing out of the scope.

## 3. Architecture & Submodules

The codebase is strictly separated by responsibility to ensure clean boundaries between AST parsing and UI rendering.

- **`prepare/`**: The core parsing engine. Responsible for resolving the current scope, extracting semantic payloads via Probes, and aggregating the Outline. (See [prepare/anchor_point/probe/README.md](prepare/anchor_point/probe/README.md) for details on Probes).
- **`schema/`**: Declarative definitions. Contains the raw Tree-sitter node mappings per language, action allowlists, and the constants that define Hydra UI layouts.
- **`menu/`**: The presentation layer. Responsible for assembling the Hydra specification, rendering row labels, and grouping items.
- **`ops/`**: The execution layer. Contains the actual implementation logic for the actions exposed in the Interact column.
- **`lib/`**: Generic utilities and action wrappers (e.g., `atlantis_action.lua`).

## 4. Developer Workflow: Adding an Action

To add a new action to the Interact menu:

1. **Enable it**: Turn the action on for the appropriate anchor kinds in `schema/actions/anchor/init.lua`.
2. **Define UI**: Add the row metadata (labels, icons, hotkeys) in `schema/actions/menu/init.lua`.
3. **Implement**: Provide the execution logic under `ops/actions/` so the resolver can find and execute `build(ctx, anchor_kind)`.
