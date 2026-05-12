# Atlantis Navigation & Function Outline Refinement (2026-05-11)

This session focused on transitioning the Atlantis surveyor from an aggressive "wrapper expansion" model to a more robust, resilient extraction system. This shift resolved critical bugs where function bodies were disappearing and redundant identifiers were cluttering the UI, while also completing the spatial navigation model.

---

## Part 1: Directional Navigation (The "l" Key)

The goal was to finalize the "D-pad" spatial navigation model for Atlantis. In Atlantis, `h` (left/out) takes you to the semantic parent, and now `l` (right/in) takes you into the first child.

### 1. [Lua] `nvChad/starter/lua/configs/hydra/atlantis_nouveau/menu/sections/navigate.lua`
**Analysis**: This change completes the "D-pad" spatial navigation model. The engineering decision was to derive the `l` target directly from the first element of the pre-filtered `outline`. This ensures that "drilling down" is a semantic action: the `l` key will automatically skip suppressed nodes (like function names) and land on the first truly interactive child.

```diff
@@ -90,6 +90,16 @@ function M.build(result)
+  if result.outline and #result.outline > 0 then
+    local child = result.outline[1]
+    table.insert(context_items, {
+      key    = "l",
+      icon   = "󰜴",
+      label  = string.format("to child [%s]", child.label),
+      action = function() jump_and_reopen(result.bufnr, child) end,
+    })
+  end
```

---

## Part 2: Resilient Function & Assignment Outlines

We overhauled how constructs are extracted and surfaced to ensure stability across diverse Tree-sitter grammars and complex nested structures.

### 2. [Rust] `atlantis-surveyor/src/model/lang/languages/lua.rs`
**Analysis**: We shifted from strict field matching to broad kind/text searches. This decoupling ensures that Atlantis remains stable even if a grammar changes its field labels (e.g., "block" vs "body"). Crucially, for assignments, we replaced fragile string-offset math with a recursive child search, ensuring that both the name (`[n]`) and the value (`[v]`) are correctly identified and pinned to their actual nodes.

```diff
@@ -30,10 +30,15 @@ impl Extract<FunctionDeclaration> for Lua {
-        let name_node = raw.field("name").or_else(|| { ... })
+        let find_child = |kinds: &[&str]| {
+            raw.children.iter().find(|c| kinds.contains(&c.kind.as_str()))
+                .or_else(|| {
+                    raw.children.iter()
+                        .find_map(|c| c.children.iter().find(|gc| kinds.contains(&gc.kind.as_str())))
+                })
+        };
+
+        let variable_list = find_child(&["variable_list", "identifier"]);
+        let expression_list = find_child(&["expression_list", "value"]);
```

### 3. [Rust] `atlantis-surveyor/src/survey/focused_node/navigation/binary_navigation.rs`
**Analysis**: We generalized the `binary_expression` flattener into a `flatten_outline` pass. By adding `assignment_statement`, `variable_list`, and `expression_list` to the "transparent types" list, we ensure that focus on a high-level declaration automatically surfaces its granular components (like variables and values) directly in the outline.

```diff
@@ -36,27 +36,26 @@
-pub(in crate::survey::focused_node) fn flatten_binary_outline(lang: Language, outline: &mut Vec<OutlineItem>) {
+pub(in crate::survey::focused_node) fn flatten_outline(lang: Language, outline: &mut Vec<OutlineItem>) {
+    let transparent_types = [
+        "binary_expression",
+        "assignment_statement",
+        "variable_list",
+        "expression_list",
+        "arguments",
+    ];
```

### 4. [Rust] `atlantis-surveyor/src/survey/focused_node/mod.rs`
**Analysis**: Simplified the outline pipeline by removing recursive expansion and replacing it with the targeted `flatten_outline` pass. This results in a predictable, linear flow: Compute -> Suppress -> Flatten -> Hint.

```diff
@@ -81,2 +81,2 @@
-        // Flatten binary expressions (e.g. x + y -> [x, y]).
-        navigation::binary_navigation::flatten_binary_outline(lang, &mut outline);
+        // Flatten binary expressions and structural wrappers (e.g. x + y -> [x, y], local x = 1 -> [x, 1]).
+        navigation::binary_navigation::flatten_outline(lang, &mut outline);
```

### 5. [Rust] `atlantis-surveyor/src/tests/lua/outline_hints.rs`
**Analysis**: Updated the test suite to validate the restored expansion behavior. The tests now verify that a `variable_declaration` correctly produces distinct outline items for both the name and the value with their pinned hotkeys.

```diff
@@ -133,3 +133,5 @@
-    assert_eq!(outline.len(), 1, "wrapper should not be expanded anymore");
-    assert_eq!(outline[0].node_type, "assignment_statement");
-    assert_eq!(outline[0].hint_key, Some("n"));
+    assert_eq!(outline.len(), 2, "wrapper should be expanded to show both sides of the assignment");
+    assert_eq!(outline[0].node_type, "variable_list");
+    assert_eq!(outline[0].hint_key, Some("n"));
+    assert_eq!(outline[1].node_type, "expression_list");
+    assert_eq!(outline[1].hint_key, Some("v"));
```

---

## Part 3: Architectural Cleanup (Bloat Removal)

We removed the hooks added for the discarded expansion logic to keep the API surface minimal and maintainable.

### 6. [Rust] `atlantis-surveyor/src/action/mod.rs`
**Analysis**: Removed `name()` and `is_container()` from the `ConstructActions` trait, as we no longer need to "ask" a node if it's a wrapper for geometric expansion.

### 7. [Rust] `atlantis-surveyor/src/model/atlantis_node.rs`
**Analysis**: Removed the enum dispatch methods for the removed trait functions, cleaning up the primary API used by the surveyor.

### 8. [Rust] `atlantis-surveyor/src/model/lang/macros.rs`
**Analysis**: Stripped the abandoned methods from the language-resolver macro, reducing code volume and complexity in the core resolver.

### 9. [Rust] `atlantis-surveyor/src/model/node/mod.rs`
**Analysis**: Removed `NodeRange::contains()` since the new pipeline uses exact start-position matching rather than geometric containment.

### 10. [Rust] `atlantis-surveyor/src/probe/treesitter/types.rs`
**Analysis**: Removed the `From<&OutlineItem> for RawNode` bridge, which was only used for re-classifying items during recursive expansion.

---
**Summary**: 10 files changed. Atlantis is now leaner, faster, and correctly surfaces granular navigation targets in assignments without sacrificing function outline stability.
