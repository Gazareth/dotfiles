use crate::tests::lua::*;
use crate::survey::NavigationInfo;
use crate::probe::treesitter::{NodeOutline, NodeSnapshot, SnapshotChild};
use crate::probe::language::Language;

use crate::model::node::NodeRange;

#[test]
fn parent_navigation_can_target_containers() {
    // Structure: block -> variable_declaration -> assignment_statement
    // All starting at (1, 0)
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let r2 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 30 };
    let r3 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 40 };

    let assignment = NodeOutline::new("assignment_statement", r0.clone());
    let variable   = NodeOutline::new("variable_declaration", r1.clone());
    // block has multiple statements — child_count > 1 so it is a Recognised navigation target.
    let block      = NodeOutline { node_type: "block".into(), range: r2.clone(), child_count: 2 };
    let function   = NodeOutline::new("function_declaration", r3.clone());

    let all = vec![&assignment, &variable, &block, &function];
    let snapshot = NodeSnapshot {
        node_type: "variable_declaration".into(),
        text: "".into(),
        range: r0.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    // Focus is variable_declaration (idx 1)
    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 1, &snapshot);

    // Parent should be the block (idx 2)
    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "block");
}

#[test]
fn parent_navigation_skips_same_kind_constructs() {
    // Structure: variable_declaration -> assignment_statement
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let r2 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 30 };
    let assignment = NodeOutline::new("assignment_statement", r0.clone());
    let variable   = NodeOutline::new("variable_declaration", r1.clone());
    let function   = NodeOutline::new("function_declaration", r2.clone());

    let all = vec![&assignment, &variable, &function];
    let snapshot = NodeSnapshot {
        node_type: "assignment_statement".into(),
        text: "".into(),
        range: r0.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    // Focus is assignment_statement (idx 0)
    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    // Parent should skip variable_declaration (same class: Assignment) and go to function_declaration
    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "function_declaration");
}

#[test]
fn parent_navigation_jumps_across_different_construct_kinds() {
    // Structure: function_declaration -> variable_declaration -> function_call
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let r2 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 30 };

    let call     = NodeOutline::new("function_call",        r0.clone());
    let variable = NodeOutline::new("variable_declaration", r1.clone());
    let function = NodeOutline::new("function_declaration", r2.clone());

    let all = vec![&call, &variable, &function];
    let snapshot = NodeSnapshot {
        node_type: "function_call".into(),
        text: "".into(),
        range: r0.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    // Focus is function_call (idx 0)
    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    // Parent should be variable_declaration (different kind: Assignment vs Call)
    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "variable_declaration");
}

#[test]
fn parent_navigation_jumps_from_assignment_to_conditional() {
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };

    let assignment  = NodeOutline::new("assignment_statement", r0.clone());
    let conditional = NodeOutline::new("if_statement",         r1.clone());

    let all = vec![&assignment, &conditional];
    let snapshot = NodeSnapshot {
        node_type: "assignment_statement".into(),
        text: "".into(),
        range: r0.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "if_statement");
}

#[test]
fn from_ancestry_returns_unsupported_language_when_no_node_matches() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let unknown = NodeOutline::new("comment",      r0.clone());
    let root    = NodeOutline::new("unknown_root", r1.clone());

    let ancestry = NodeAncestry::new_test(vec![unknown], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None);

    match result {
        Ok(None) => {},
        Ok(Some(_)) => panic!("Expected Ok(None), got Ok(Some)"),
        Err(e) => panic!("Expected Ok(None), got Err({:?})", e),
    }
}

#[test]
fn unrecognised_tokens_climb_to_recognised_parent() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // Simulate cursor on `local` or `function` keyword
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let local_kw  = NodeOutline::new("local",                range.clone());
    let func_decl = NodeOutline::new("function_declaration", range.clone());
    let root      = NodeOutline::new("chunk",                range.clone());

    let ancestry = NodeAncestry::new_test(vec![local_kw, func_decl], root, Language::Lua);

    crate::tests::helpers::snap("function_declaration").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration");
}

#[test]
fn leaf_tokens_stop_climbing() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // Simulate cursor on `x` inside `expression_list`
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let ident     = NodeOutline::new("identifier",      range.clone());
    let expr_list = NodeOutline { node_type: "expression_list".into(), range: range.clone(), child_count: 2 };
    let root      = NodeOutline::new("chunk",           range.clone());

    let ancestry = NodeAncestry::new_test(vec![ident, expr_list], root, Language::Lua);

    crate::tests::helpers::snap("identifier").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    // identifier inside expression_list (transparent) → Leaf → stops here
    assert_eq!(result.node_type, "identifier");
}

// ── variable_list single-child climbing ──────────────────────────────────

#[test]
fn single_variable_declaration_climbs_past_identifier() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // `local x = 1` — cursor on `x`.
    // variable_list has exactly one child, so the identifier is not a focus target;
    // climbing continues to variable_declaration.
    let r_all   = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 12 };
    let r_ident = NodeRange { start_row: 0, start_col: 6, end_row: 0, end_col: 7 };

    let ident    = NodeOutline::new("identifier",         r_ident.clone());
    let var_list = NodeOutline { node_type: "variable_list".into(), range: r_ident.clone(), child_count: 1 };
    let assign   = NodeOutline::new("assignment_statement",  r_all.clone());
    let var_decl = NodeOutline::new("variable_declaration",  r_all.clone());
    let root     = NodeOutline::new("chunk",                 r_all.clone());

    let ancestry = NodeAncestry::new_test(vec![ident, var_list, assign, var_decl], root, Language::Lua);

    // variable_declaration snapshot (consumed when focus lands here).
    snap("variable_declaration")
        .child_ranged("assignment_statement", "x = 1", 0, 6, 0, 12)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "variable_declaration",
        "sole identifier in variable_list should cause focus to climb to variable_declaration");
}

#[test]
fn single_variable_bare_assignment_climbs_past_identifier() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // `x = 1` — cursor on `x`.
    // Same rule applies: variable_list with one child → skip identifier.
    let r_all   = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 5 };
    let r_ident = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 1 };

    let ident    = NodeOutline::new("identifier",         r_ident.clone());
    let var_list = NodeOutline { node_type: "variable_list".into(), range: r_ident.clone(), child_count: 1 };
    let assign   = NodeOutline::new("assignment_statement",  r_all.clone());
    let root     = NodeOutline::new("chunk",                 r_all.clone());

    let ancestry = NodeAncestry::new_test(vec![ident, var_list, assign], root, Language::Lua);

    snap("assignment_statement")
        .child_ranged("variable_list",   "x",   0, 0, 0, 1)
        .child_ranged("expression_list", "1",   0, 4, 0, 5)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "assignment_statement",
        "sole identifier in variable_list should cause focus to climb to assignment_statement");
}

#[test]
fn multi_variable_assignment_identifier_is_leaf() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // `local x, y = 1, 2` — cursor on `x`.
    // variable_list has two children, so the identifier IS a focusable Leaf.
    let r_all   = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 20 };
    let r_x     = NodeRange { start_row: 0, start_col: 6, end_row: 0, end_col: 7 };

    let ident    = NodeOutline::new("identifier",         r_x.clone());
    let var_list = NodeOutline { node_type: "variable_list".into(), range: r_all.clone(), child_count: 2 };
    let assign   = NodeOutline::new("assignment_statement",  r_all.clone());
    let var_decl = NodeOutline::new("variable_declaration",  r_all.clone());
    let root     = NodeOutline::new("chunk",                 r_all.clone());

    let ancestry = NodeAncestry::new_test(vec![ident, var_list, assign, var_decl], root, Language::Lua);

    snap("identifier").inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "identifier",
        "one of multiple variables should remain as a Leaf focus target");
}

// ── Hint navigation ───────────────────────────────────────────────────────

#[test]
fn hint_for_multi_child_expression_list_focuses_it_directly() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // expression_list with 2 children is a valid selection target — hint should focus it
    // directly, not climb.  Mirrors cursor navigation: Guard B does not fire.
    let r_assign = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 9 };
    let r_el     = NodeRange { start_row: 0, start_col: 4, end_row: 0, end_col: 9 };

    let el     = NodeOutline { node_type: "expression_list".into(), range: r_el.clone(), child_count: 2 };
    let assign = NodeOutline::new("assignment_statement", r_assign.clone());
    let root   = NodeOutline::new("chunk",                r_assign.clone());

    let ancestry = NodeAncestry::new_test(vec![el, assign], root, Language::Lua);

    snap("expression_list")
        .child_ranged("identifier", "a", 0, 4, 0, 5)
        .child_ranged("identifier", "b", 0, 7, 0, 8)
        .inject();

    let result = FocusedNode::from_ancestry(
        ancestry,
        Some(("expression_list", 0, 4)),
    ).unwrap().unwrap();

    assert_eq!(result.node_type, "expression_list",
        "hint to multi-child expression_list should focus it directly");
}

// ── Single-child transparent node resolution ──────────────────────────────

#[test]
fn single_child_expression_list_with_table_constructor_focuses_table() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // `local widths = { 0, 0, 0 }` — hint navigates to expression_list (1 child: table_constructor).
    // expression_list → Unrecognised (Guard B: transparent, ≤1 child).
    // table_constructor has 3 children → Recognised → should become the focus.
    let r_all   = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 26 };
    let r_table = NodeRange { start_row: 0, start_col: 15, end_row: 0, end_col: 26 };
    let r_el    = NodeRange { start_row: 0, start_col: 15, end_row: 0, end_col: 26 };

    let table  = NodeOutline { node_type: "table_constructor".into(), range: r_table.clone(), child_count: 3 };
    let el     = NodeOutline { node_type: "expression_list".into(),   range: r_el.clone(),    child_count: 1 };
    let assign = NodeOutline::new("assignment_statement",  r_all.clone());
    let var    = NodeOutline::new("variable_declaration",  r_all.clone());
    let root   = NodeOutline::new("chunk",                 r_all.clone());

    let ancestry = NodeAncestry::new_test(vec![table, el, assign, var], root, Language::Lua);

    snap("table_constructor")
        .child_ranged("integer", "0", 0, 17, 0, 18)
        .child_ranged("integer", "0", 0, 20, 0, 21)
        .child_ranged("integer", "0", 0, 23, 0, 24)
        .inject();

    let result = FocusedNode::from_ancestry(
        ancestry,
        Some(("expression_list", 0, 15)),
    ).unwrap().unwrap();

    assert_eq!(result.node_type, "table_constructor",
        "single-child expression_list wrapping a multi-child table_constructor should focus the table");
}

#[test]
fn single_child_expression_list_with_simple_value_climbs_to_variable_declaration() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // `local x = 1` — hint navigates to expression_list (1 child: integer literal).
    // expression_list → Unrecognised; inner is Leaf (not Recognised) → climb outward.
    // assignment_statement and variable_declaration are both Assignment → walk merges to variable_declaration.
    let r_all   = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 12 };
    let r_val   = NodeRange { start_row: 0, start_col: 11, end_row: 0, end_col: 12 };
    let r_el    = NodeRange { start_row: 0, start_col: 11, end_row: 0, end_col: 12 };

    let integer = NodeOutline::new("integer",            r_val.clone());
    let el      = NodeOutline { node_type: "expression_list".into(), range: r_el.clone(), child_count: 1 };
    let assign  = NodeOutline::new("assignment_statement", r_all.clone());
    let var     = NodeOutline::new("variable_declaration", r_all.clone());
    let root    = NodeOutline::new("chunk",                r_all.clone());

    let ancestry = NodeAncestry::new_test(vec![integer, el, assign, var], root, Language::Lua);

    snap("variable_declaration")
        .child_ranged("assignment_statement", "x = 1", 0, 6, 0, 12)
        .inject();

    let result = FocusedNode::from_ancestry(
        ancestry,
        Some(("expression_list", 0, 11)),
    ).unwrap().unwrap();

    assert_eq!(result.node_type, "variable_declaration",
        "single-child expression_list with a simple value should climb through assignment_statement to variable_declaration");
}

// ── Function component sibling navigation ─────────────────────────────────

#[test]
fn parameters_siblings_include_return_statement() {
    // When focused on a multi-param parameters node inside a function, the sibling
    // set should be [parameters, block, return_statement] — cycling between function parts.
    let fn_range  = NodeRange { start_row: 0, start_col: 0, end_row: 5, end_col: 3 };
    let p_range   = NodeRange { start_row: 0, start_col: 9, end_row: 0, end_col: 16 };
    let b_range   = NodeRange { start_row: 1, start_col: 0, end_row: 4, end_col: 3 };
    let ret_range = NodeRange { start_row: 3, start_col: 2, end_row: 3, end_col: 10 };

    let params = NodeOutline { node_type: "parameters".into(), range: p_range.clone(), child_count: 2 };
    let func   = NodeOutline::new("function_declaration", fn_range.clone());
    let root   = NodeOutline::new("chunk",                fn_range.clone());
    let all    = vec![&params, &func, &root];

    let snapshot = NodeSnapshot {
        node_type: "parameters".into(),
        text:      "(x, y)".into(),
        range:     p_range.clone(),
        fields:    Default::default(),
        children:  vec![
            SnapshotChild { node_type: "identifier".into(), text: "x".into(), range: NodeRange { start_row: 0, start_col: 10, end_row: 0, end_col: 11 } },
            SnapshotChild { node_type: "identifier".into(), text: "y".into(), range: NodeRange { start_row: 0, start_col: 13, end_row: 0, end_col: 14 } },
        ],
        siblings: vec![],
    };

    // Snap 1: semantic parent (function_declaration) — consumed by resolve_siblings_general.
    snap("function_declaration")
        .child_ranged("identifier",  "add",    0, 9, 0, 12)
        .child_ranged("parameters",  "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block",       "...",    b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .queue();
    // Snap 2: block child — consumed by resolve_child_sibling to check its child_count.
    snap("block")
        .child_ranged("variable_declaration", "local z = x + y", 2, 2, 2, 18)
        .child_ranged("return_statement",     "return z", ret_range.start_row, ret_range.start_col, ret_range.end_row, ret_range.end_col)
        .queue();
    // Snap 3: block again — consumed by maybe_add_return_sibling to find the return statement.
    snap("block")
        .child_ranged("variable_declaration", "local z = x + y", 2, 2, 2, 18)
        .child_ranged("return_statement",     "return z", ret_range.start_row, ret_range.start_col, ret_range.end_row, ret_range.end_col)
        .queue();

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let next = nav.next_sibling.as_ref().expect("should have next sibling");
    assert_eq!(next.node_type, "block", "next sibling of parameters should be block");

    let prev = nav.prev_sibling.as_ref().expect("should have prev sibling");
    assert_eq!(prev.node_type, "return_statement", "prev sibling of parameters should wrap to return_statement");
}

#[test]
fn body_siblings_include_params_and_return() {
    // When focused on the block (Body) inside a function, siblings should include
    // parameters and return_statement, found in node_snapshot.children directly.
    let fn_range  = NodeRange { start_row: 0, start_col: 0, end_row: 5, end_col: 3 };
    let p_range   = NodeRange { start_row: 0, start_col: 9, end_row: 0, end_col: 16 };
    let b_range   = NodeRange { start_row: 1, start_col: 0, end_row: 4, end_col: 3 };
    let ret_range = NodeRange { start_row: 3, start_col: 2, end_row: 3, end_col: 10 };

    let block = NodeOutline { node_type: "block".into(), range: b_range.clone(), child_count: 2 };
    let func  = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let all   = vec![&block, &func, &root];

    let snapshot = NodeSnapshot {
        node_type: "block".into(),
        text:      "...".into(),
        range:     b_range.clone(),
        fields:    Default::default(),
        children:  vec![
            SnapshotChild { node_type: "variable_declaration".into(), text: "local z = x + y".into(), range: NodeRange { start_row: 2, start_col: 2, end_row: 2, end_col: 18 } },
            SnapshotChild { node_type: "return_statement".into(),     text: "return z".into(),         range: ret_range.clone() },
        ],
        siblings: vec![],
    };

    // Snap 1: semantic parent (function_declaration) — consumed by resolve_siblings_general.
    snap("function_declaration")
        .child_ranged("identifier",  "add",    0, 9, 0, 12)
        .child_ranged("parameters",  "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block",       "...",    b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .queue();
    // Snap 2: parameters child — consumed by resolve_child_sibling to check its child_count.
    snap("parameters")
        .child_ranged("identifier", "x", 0, 10, 0, 11)
        .child_ranged("identifier", "y", 0, 13, 0, 14)
        .queue();

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let prev = nav.prev_sibling.as_ref().expect("should have prev sibling");
    assert_eq!(prev.node_type, "parameters", "prev sibling of block should be parameters");

    let next = nav.next_sibling.as_ref().expect("should have next sibling");
    assert_eq!(next.node_type, "return_statement", "next sibling of block should be return_statement");
}

#[test]
fn return_statement_siblings_include_params_and_body() {
    // When focused on return_statement inside a function body, sibling navigation
    // should cycle between function-level components [params, body, return],
    // not the body's statement-level siblings.
    let fn_range  = NodeRange { start_row: 0, start_col: 0, end_row: 5, end_col: 3 };
    let p_range   = NodeRange { start_row: 0, start_col: 9, end_row: 0, end_col: 16 };
    let b_range   = NodeRange { start_row: 1, start_col: 0, end_row: 4, end_col: 3 };
    let ret_range = NodeRange { start_row: 3, start_col: 2, end_row: 3, end_col: 10 };

    let ret_node = NodeOutline { node_type: "return_statement".into(), range: ret_range.clone(), child_count: 0 };
    let block    = NodeOutline { node_type: "block".into(),            range: b_range.clone(),   child_count: 2 };
    let func     = NodeOutline::new("function_declaration", fn_range.clone());
    let root     = NodeOutline::new("chunk",                fn_range.clone());
    let all      = vec![&ret_node, &block, &func, &root];

    let snapshot = NodeSnapshot {
        node_type: "return_statement".into(),
        text:      "return z".into(),
        range:     ret_range.clone(),
        fields:    Default::default(),
        children:  vec![],
        siblings:  vec![
            SnapshotChild { node_type: "variable_declaration".into(), text: "local z = x + y".into(), range: NodeRange { start_row: 2, start_col: 2, end_row: 2, end_col: 18 } },
            SnapshotChild { node_type: "return_statement".into(),     text: "return z".into(),         range: ret_range.clone() },
        ],
    };

    // Block snapshot — siblings are the function's named children
    snap("block")
        .sibling_ranged("identifier",  0,  9, 0, 12)
        .sibling_ranged("parameters",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .sibling_ranged("block",       b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .inject();

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let prev = nav.prev_sibling.as_ref().expect("should have prev sibling");
    assert_eq!(prev.node_type, "block", "prev sibling of return_statement should be block (body)");

    let next = nav.next_sibling.as_ref().expect("should have next sibling");
    assert_eq!(next.node_type, "parameters", "next sibling of return_statement should wrap to parameters");
}

#[test]
fn statement_inside_function_body_excludes_return_from_siblings() {
    // Statements inside a function body should not see return_statement as a sibling.
    // The return is promoted to a function-level component (handled separately).
    let fn_range  = NodeRange { start_row: 0, start_col: 0, end_row: 5, end_col: 3 };
    let b_range   = NodeRange { start_row: 1, start_col: 0, end_row: 4, end_col: 3 };
    let s1_range  = NodeRange { start_row: 1, start_col: 2, end_row: 1, end_col: 18 };
    let s2_range  = NodeRange { start_row: 2, start_col: 2, end_row: 2, end_col: 18 };
    let ret_range = NodeRange { start_row: 3, start_col: 2, end_row: 3, end_col: 10 };

    let stmt  = NodeOutline { node_type: "variable_declaration".into(), range: s1_range.clone(), child_count: 0 };
    let block = NodeOutline { node_type: "block".into(),                range: b_range.clone(),  child_count: 2 };
    let func  = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let all   = vec![&stmt, &block, &func, &root];

    let snapshot = NodeSnapshot {
        node_type: "variable_declaration".into(),
        text:      "local z = x + y".into(),
        range:     s1_range.clone(),
        fields:    Default::default(),
        children:  vec![],
        siblings:  vec![
            SnapshotChild { node_type: "variable_declaration".into(), text: "local z = x + y".into(), range: s1_range.clone() },
            SnapshotChild { node_type: "variable_declaration".into(), text: "local w = 1".into(),     range: s2_range.clone() },
            SnapshotChild { node_type: "return_statement".into(),     text: "return z".into(),         range: ret_range.clone() },
        ],
    };

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    if let Some(next) = &nav.next_sibling {
        assert_ne!(next.node_type, "return_statement", "next sibling should not be return_statement");
    }
    if let Some(prev) = &nav.prev_sibling {
        assert_ne!(prev.node_type, "return_statement", "prev sibling should not be return_statement");
    }
}

// ── Single-parameter function sibling navigation ──────────────────────────

#[test]
fn single_parameter_siblings_include_body_and_return() {
    // When focused on the sole parameter identifier inside a transparent parameters list,
    // sibling navigation should cycle [identifier(x), block, return_statement].
    let fn_range  = NodeRange { start_row: 0, start_col: 0,  end_row: 4, end_col: 3 };
    let p_range   = NodeRange { start_row: 0, start_col: 12, end_row: 0, end_col: 15 }; // "(x)"
    let x_range   = NodeRange { start_row: 0, start_col: 13, end_row: 0, end_col: 14 }; // "x"
    let b_range   = NodeRange { start_row: 1, start_col: 0,  end_row: 4, end_col: 3 };
    let ret_range = NodeRange { start_row: 3, start_col: 2,  end_row: 3, end_col: 10 };

    let ident  = NodeOutline::new("identifier",          x_range.clone());
    let params = NodeOutline { node_type: "parameters".into(), range: p_range.clone(), child_count: 1 };
    let func   = NodeOutline::new("function_declaration", fn_range.clone());
    let root   = NodeOutline::new("chunk",                fn_range.clone());
    let all    = vec![&ident, &params, &func, &root];

    let snapshot = NodeSnapshot {
        node_type: "identifier".into(),
        text:      "x".into(),
        range:     x_range.clone(),
        fields:    Default::default(),
        children:  vec![],
        siblings:  vec![],
    };

    // Snap 1: function_declaration — sp snapshot in resolve_siblings_general.
    snap("function_declaration")
        .child_ranged("identifier",  "foo",  0, 9,  0, 12)
        .child_ranged("parameters",  "(x)",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block",       "...",  b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .queue();
    // Snap 2: parameters — consumed by resolve_child_sibling (translucent descent).
    snap("parameters")
        .child_ranged("identifier", "x", x_range.start_row, x_range.start_col, x_range.end_row, x_range.end_col)
        .queue();
    // Snap 3: block — consumed by resolve_child_sibling (is_body=true, snapped to get child_count).
    snap("block")
        .child_ranged("variable_declaration", "local z = 1", 2, 2, 2, 14)
        .child_ranged("return_statement",     "return z",    ret_range.start_row, ret_range.start_col, ret_range.end_row, ret_range.end_col)
        .queue();
    // Snap 4: block — consumed by Change-3 parameter-focus return-sibling search.
    snap("block")
        .child_ranged("variable_declaration", "local z = 1", 2, 2, 2, 14)
        .child_ranged("return_statement",     "return z",    ret_range.start_row, ret_range.start_col, ret_range.end_row, ret_range.end_col)
        .queue();

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let next = nav.next_sibling.as_ref().expect("should have next sibling");
    assert_eq!(next.node_type, "block", "next sibling of single param should be block");

    let prev = nav.prev_sibling.as_ref().expect("should have prev sibling");
    assert_eq!(prev.node_type, "return_statement", "prev sibling of single param should wrap to return_statement");
}

#[test]
fn return_statement_siblings_with_single_param_function_uses_parameter_not_list() {
    // When focused on return_statement in a single-param function, the [params, body, return]
    // cycle should substitute the identifier for the transparent parameters list.
    let fn_range  = NodeRange { start_row: 0, start_col: 0,  end_row: 4, end_col: 3 };
    let p_range   = NodeRange { start_row: 0, start_col: 12, end_row: 0, end_col: 15 };
    let x_range   = NodeRange { start_row: 0, start_col: 13, end_row: 0, end_col: 14 };
    let b_range   = NodeRange { start_row: 1, start_col: 0,  end_row: 4, end_col: 3 };
    let ret_range = NodeRange { start_row: 3, start_col: 2,  end_row: 3, end_col: 10 };

    let ret_node = NodeOutline { node_type: "return_statement".into(), range: ret_range.clone(), child_count: 0 };
    let block    = NodeOutline { node_type: "block".into(),            range: b_range.clone(),   child_count: 2 };
    let func     = NodeOutline::new("function_declaration", fn_range.clone());
    let root     = NodeOutline::new("chunk",                fn_range.clone());
    let all      = vec![&ret_node, &block, &func, &root];

    let snapshot = NodeSnapshot {
        node_type: "return_statement".into(),
        text:      "return z".into(),
        range:     ret_range.clone(),
        fields:    Default::default(),
        children:  vec![],
        siblings:  vec![],
    };

    // Snap 1: block — consumed by collect_function_components_for_return.
    // Siblings are the function_declaration's named children.
    snap("block")
        .sibling_ranged("identifier",  0,  9, 0, 12)
        .sibling_ranged("parameters",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .sibling_ranged("block",       b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .queue();
    // Snap 2: parameters — consumed by redirect_transparent_param_nav_target (Change 5).
    snap("parameters")
        .child_ranged("identifier", "x", x_range.start_row, x_range.start_col, x_range.end_row, x_range.end_col)
        .queue();

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let prev = nav.prev_sibling.as_ref().expect("should have prev sibling");
    assert_eq!(prev.node_type, "block", "prev sibling of return_statement should be block (body)");

    let next = nav.next_sibling.as_ref().expect("should have next sibling");
    assert_eq!(next.node_type, "identifier",
        "next sibling of return_statement should be the parameter identifier, not the parameters list");
}

// ── Assignment component sibling navigation ───────────────────────────────

#[test]
fn assignment_name_and_value_are_siblings() {
    // variable_list and expression_list are AST siblings inside assignment_statement.
    // When focused on variable_list (multi-child), expression_list should be its sibling.
    let a_range   = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 12 };
    let lhs_range = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 4 };
    let val_range = NodeRange { start_row: 0, start_col: 7, end_row: 0, end_col: 12 };

    let vlist  = NodeOutline { node_type: "variable_list".into(),   range: lhs_range.clone(), child_count: 2 };
    let assign = NodeOutline::new("assignment_statement", a_range.clone());
    let root   = NodeOutline::new("chunk",                a_range.clone());
    let all    = vec![&vlist, &assign, &root];

    let snapshot = NodeSnapshot {
        node_type: "variable_list".into(),
        text:      "x, y".into(),
        range:     lhs_range.clone(),
        fields:    Default::default(),
        children:  vec![
            SnapshotChild { node_type: "identifier".into(), text: "x".into(), range: NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 1 } },
            SnapshotChild { node_type: "identifier".into(), text: "y".into(), range: NodeRange { start_row: 0, start_col: 3, end_row: 0, end_col: 4 } },
        ],
        siblings: vec![],
    };

    // Snap 1: semantic parent (assignment_statement) — consumed by resolve_siblings_general.
    snap("assignment_statement")
        .child_ranged("variable_list",   "x, y", lhs_range.start_row, lhs_range.start_col, lhs_range.end_row, lhs_range.end_col)
        .child_ranged("expression_list", "1, 2",  val_range.start_row, val_range.start_col, val_range.end_row, val_range.end_col)
        .queue();
    // Snap 2: expression_list child — consumed by resolve_child_sibling to check its child_count.
    snap("expression_list")
        .child_ranged("number", "1", 0, 7, 0, 8)
        .child_ranged("number", "2", 0, 10, 0, 11)
        .queue();

    let nav = NavigationInfo::from_snapshot(Language::Lua, &all, 0, &snapshot);

    let next = nav.next_sibling.as_ref().expect("should have next sibling");
    assert_eq!(next.node_type, "expression_list", "next sibling of variable_list should be expression_list");

    let prev = nav.prev_sibling.as_ref().expect("should have prev sibling");
    assert_eq!(prev.node_type, "expression_list", "prev sibling wraps back to expression_list");
}
