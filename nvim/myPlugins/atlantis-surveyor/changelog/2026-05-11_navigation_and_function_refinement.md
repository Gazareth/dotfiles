# Atlantis Navigation & Function Outline Refinement (2026-05-11)

This document provides a comprehensive technical analysis of the changes committed on 2026-05-11. The session focused on shifting Atlantis from a geometric, auto-expanding surveyor to a semantic, resilient extraction model. This resolved critical bugs regarding missing function bodies and redundant identifiers while completing the directional navigation UI.

---

## Section 1: Navigation & Feature Enhancements

### 1. [Lua] `nvChad/starter/lua/configs/hydra/atlantis_nouveau/menu/sections/navigate.lua`

**Analysis**: This change completes the "D-pad" spatial navigation model for Atlantis. While `h` has always provided a path to the semantic parent, the lack of an `l` (drill-down) key created a navigational dead-end. The engineering decision here was to derive the `l` target directly from the first element of the already-computed and filtered `outline`. This is critical because it ensures that "drilling down" is a semantic action, not just a geometric one; the `l` key will automatically skip suppressed nodes (like the function name) and land on the first truly interactive child (like parameters or the body).

```diff
@@ -90,6 +90,16 @@ function M.build(result)
-      })
-    end
-  end
+      })
+    end
+  end
+
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

### 2. [Rust] `atlantis-surveyor/src/model/lang/languages/lua.rs`

**Analysis**: This is the core "Resilience" fix. Tree-sitter grammars for Lua are notoriously inconsistent across different versions and implementations (e.g., one might use a `body` field while another uses `block`). By moving from strict field-name lookups to a broader search based on node "kinds" (searching for substrings like "identifier" or "block"), we decouple Atlantis from the specific naming conventions of any single grammar. This ensures that the extractor always finds the function's name (to suppress it) and the function's body (to hint it), providing a stable UI regardless of the underlying parser configuration.

```diff
@@ -30,10 +30,15 @@ impl Extract<FunctionDeclaration> for Lua {
     fn extract(raw: &RawNode) -> FunctionDeclaration {
         let name_node = raw.field("name").or_else(|| {
             raw.children.iter().find(|c| {
-                c.kind == "identifier" || c.kind == "dot_index_expression" || c.kind == "method_index_expression"
-            })
-        });
+                let k = c.kind.to_lowercase();
+                k.contains("identifier") || k.contains("name") || k.contains("index_expression")
+            })
+        });
+
+        let body_node = raw.field("block")
+            .or_else(|| raw.field("body"))
+            .or_else(|| raw.children.iter().find(|c| c.kind == "block"));
```

---

## Section 2: Core Pipeline Stabilization

### 3. [Rust] `atlantis-surveyor/src/survey/focused_node/mod.rs`

**Analysis**: This file represents the "rebalancing" of the surveyor's logic. We discarded a complex, recursive "wrapper expansion" loop that was attempting to automatically flatten the AST. While well-intentioned, that logic was geometrically over-aggressive and was incorrectly "swallowing" semantic containers like function bodies because they were being treated as transparent wrappers. The new architecture returns to a predictable, linear pipeline: compute the raw children, filter out exceptions (like the function name), and then apply semantic overlays (hints). This ensures that every node in the outline is a stable, intentional navigation target.

```diff
@@ -73,15 +73,15 @@ impl FocusedNode {
-        // Suppress any nodes that are explicitly marked as exceptions by the focus node.
-        // This is where identifiers/names are filtered out.
+        // Suppress identifiers/names by matching their start position against exceptions.
         let exceptions = node.outline_exceptions();
         outline.retain(|item| {
             !exceptions.iter().any(|ex| {
                 ex.start_row == item.range.start_row && ex.start_col == item.range.start_col
             })
         });
 
-        // Stamp hint_key on any outline item whose range matches a keyed NavigationTarget.
+        // Stamp hotkey hints (e.g. [p] for parameters, [b] for body).
         let hints = node.keyed_outline_hints();
         for item in &mut outline {
-            for (h_range, h_key) in &hints {
-                if h_range.start_row == item.range.start_row && h_range.start_col == item.range.start_col {
-                    item.hint_key = Some(h_key);
-                    break;
-                }
+            if let Some((_, key)) = hints.iter().find(|(r, _)| {
+                r.start_row == item.range.start_row && r.start_col == item.range.start_col
+            }) {
+                item.hint_key = Some(key);
             }
         }
```

### 4. [Rust] `atlantis-surveyor/src/tests/lua/outline_hints.rs`

**Analysis**: This test update serves as the formal validation of the new "non-expanding" architecture. We updated the assertions for `variable_declaration` nodes to reflect that they are now preserved as cohesive semantic units rather than being recursively expanded into their constituent parts. This confirms that our integration tests are accurately guarding the simplified pipeline and preventing a regression to the over-aggressive expansion behavior.

```diff
@@ -133,6 +133,6 @@ fn variable_declaration_wrapper_is_expanded_and_hints_stamped() {
-    assert_eq!(outline.len(), 2, "wrapper should be expanded");
-    assert_eq!(outline[0].node_type, "variable_list");
-    assert_eq!(outline[1].node_type, "expression_list");
+    assert_eq!(outline.len(), 1, "wrapper should not be expanded anymore");
+    assert_eq!(outline[0].node_type, "assignment_statement");
+    assert_eq!(outline[0].hint_key, Some("n"));
```

---

## Section 3: Architectural Cleanup (Bloat Removal)

The following changes represent the removal of "scaffolding" that was implemented during the development of the discarded expansion logic. These deletions restore the codebase to a lean state and reduce the surface area for future maintenance.

### 5. [Rust] `atlantis-surveyor/src/action/mod.rs`

**Analysis**: The `ConstructActions` trait was previously burdened with `is_container()` and `name()` methods that were used to guide the expansion loop. By deleting these, we simplify the "contract" that any new language implementation must fulfill. This keeps the core plugin architecture focused on classification and action-dispatch rather than geometric peeking.

```diff
@@ -11,8 +11,6 @@ pub trait ConstructActions: std::fmt::Debug + Send + Sync {
-    /// Optional semantic name of this specific instance (e.g. function name).
-    fn name(&self) -> Option<String>;
-
-    /// Whether this node acts as a transparent container for other navigation targets.
-    fn is_container(&self) -> bool;
```

### 6. [Rust] `atlantis-surveyor/src/model/atlantis_node.rs`

**Analysis**: As the top-level wrapper for all resolved nodes, `AtlantisNode` had inherited the `is_container` and `name` methods. Removing these cleans up the primary API that the surveyor uses to interact with nodes, ensuring that we only expose properties that are actually consumed by the UI pipeline.

```diff
@@ -66,12 +66,0 @@ impl AtlantisNode {
-    pub fn is_container(&self) -> bool {
-        match self {
-            AtlantisNode::Recognised(n) => n.is_container(),
-            _ => false,
-        }
-    }
-
-    pub fn name(&self) -> Option<String> {
-        match self {
-            AtlantisNode::Recognised(n) => n.name(),
-            _ => None,
-        }
-    }
```

### 7. [Rust] `atlantis-surveyor/src/model/lang/macros.rs`

**Analysis**: This change removes the automatic generation of the abandoned trait methods from the language-node resolver macro. This is a critical cleanup step because it prevents the compiler from generating hundreds of unused match-arms across every supported language, keeping the core resolver macro lean and focused only on classification, hints, and exceptions.

```diff
@@ -104,20 +104,0 @@ macro_rules! impl_lang_node_resolver {
-            fn is_container(&self) -> bool { ... }
-            fn name(&self) -> Option<String> { ... }
```

### 8. [Rust] `atlantis-surveyor/src/model/node/mod.rs`

**Analysis**: The `contains()` helper on `NodeRange` was a geometric utility added to detect if one node's bounding box nested within another. Since we shifted to an "exact anchor" matching system (where nodes are identified by their precise start row/column), geometric containment checks are no longer necessary. Removing this reduces the logic overhead in our most basic data structures.

```diff
@@ -19,4 +19,0 @@ impl NodeRange {
-    pub fn contains(&self, other: &NodeRange) -> bool {
-        (other.start_row > self.start_row || ...)
-            && (other.end_row < self.end_row || ...)
-    }
```

### 9. [Rust] `atlantis-surveyor/src/model/resolved.rs`

**Analysis**: Similar to `atlantis_node.rs`, this file contained the multi-language dispatch for the removed trait methods. Cleaning this out ensures that our dispatch layer remains a 1:1 mirror of the underlying `ConstructActions` trait, maintaining architectural consistency.

```diff
@@ -40,14 +40,0 @@ impl AnyNode {
-    pub fn is_container(&self) -> bool { ... }
-    pub fn name(&self) -> Option<String> { ... }
```

### 10. [Rust] `atlantis-surveyor/src/probe/treesitter/types.rs`

**Analysis**: The `From<&OutlineItem> for RawNode` bridge was a temporary transformation tool that allowed the surveyor to treat an outline item as a raw node for re-classification. Since we now only classify children during the initial outline generation, we no longer need to perform this data-transformation. Removing it eliminates an unnecessary conversion layer between the surveyor and the model.

```diff
@@ -62,10 +62,0 @@ impl From<&crate::model::OutlineItem> for RawNode {
-    fn from(i: &crate::model::OutlineItem) -> Self { ... }
```
