// Outline composition tests.

use crate::tests::lua::*;
use crate::survey::focused_node::FocusedNode;
use crate::survey::focused_node::ancestry::NodeAncestry;
use crate::probe::treesitter::NodeOutline;
use crate::probe::language::Language;
use crate::model::node::NodeRange;
use crate::model::AtlantisNode;

fn range(sr: u32, sc: u32, er: u32, ec: u32) -> NodeRange {
    NodeRange { start_row: sr, start_col: sc, end_row: er, end_col: ec }
}

// ── function_declaration ──────────────────────────────────────────────────

#[test]
fn function_declaration_outline_suppresses_name_identifier() {
    // A function declaration's name identifier should be suppressed from the outline.
    let fn_range   = range(0, 0, 5, 3);
    let name_range = range(0, 9, 0, 12);
    let p_range    = range(0, 12, 0, 18);
    let b_range    = range(1, 0, 4, 3);

    let focus = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        // Snap 1: function_declaration focus — consumed by from_ancestry.
        snap("function_declaration")
            .range(fn_range.start_row, fn_range.start_col, fn_range.end_row, fn_range.end_col)
            .field_ranged("name",       "add",    name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
            .field_ranged("parameters", "(x, y)", p_range.start_row,    p_range.start_col,    p_range.end_row,    p_range.end_col)
            .field_ranged("block",      "...",    b_range.start_row,    b_range.start_col,    b_range.end_row,    b_range.end_col)
            .child_ranged("identifier", "add",    name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
            .child_ranged("parameters", "(x, y)", p_range.start_row,    p_range.start_col,    p_range.end_row,    p_range.end_col)
            .child_ranged("block",      "...",    b_range.start_row,    b_range.start_col,    b_range.end_row,    b_range.end_col)
            .build(),
        // Subsequent fetches (chunk for siblings, block for enrich) will get Err(NoNode) and
        // return gracefully — this test only asserts on outline composition, not navigation.
    ]).unwrap().unwrap();

    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "identifier should be suppressed, leaving two items");
    assert!(outline.iter().all(|i| i.node_type != "identifier"), "identifier should be suppressed");
    assert!(outline.iter().any(|i| i.node_type == "parameters"), "parameters should remain");
    assert!(outline.iter().any(|i| i.node_type == "block"), "block should remain");

    let body = outline.iter().find(|i| i.node_type == "block").unwrap();
    assert_eq!(body.hint_key, Some("b"), "block should be stamped with hint_key 'b'");

    assert_eq!(result.node_type, "function_declaration");
    assert!(matches!(result.node, AtlantisNode::Recognised(_)), "function_declaration should be recognised");
    assert_eq!(result.range, fn_range, "result range should reflect the snapshot range");
    assert!(!result.navigation.is_at_top, "a top-level function has chunk as its top-level node, not itself");
}

// ── function_declaration with return statement ────────────────────────────

#[test]
fn function_declaration_outline_includes_return_statement() {
    // A function with a return statement should include it as a third outline item with hint "r".
    let fn_range  = range(0, 0, 5, 3);
    let p_range   = range(0, 12, 0, 18);
    let b_range   = range(1, 0, 4, 3);
    let ret_range = range(3, 2, 3, 10);

    let focus = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        // Snap 1: function_declaration focus — consumed by from_ancestry (node_snapshot).
        snap("function_declaration")
            .field_ranged("parameters", "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
            .field_ranged("block",      "...",    b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .child_ranged("parameters", "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
            .child_ranged("block",      "...",    b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .build(),
        // Snap 2: chunk (semantic parent of function_declaration) — consumed by resolve_siblings_general.
        snap("chunk")
            .child_ranged("function_declaration", "...", fn_range.start_row, fn_range.start_col, fn_range.end_row, fn_range.end_col)
            .build(),
        // Snap 3: block — consumed by enrich_function_outline to find the return statement.
        snap("block")
            .child_ranged("variable_declaration", "local z = x + y", 2, 2, 2, 18)
            .child_ranged("return_statement",     "return z",         ret_range.start_row, ret_range.start_col, ret_range.end_row, ret_range.end_col)
            .build(),
    ]).unwrap().unwrap();

    let outline = &result.outline;

    assert_eq!(outline.len(), 3, "return_statement should be added to the outline");

    let params = outline.iter().find(|i| i.node_type == "parameters").expect("parameters missing");
    assert_eq!(params.hint_key, Some("p"));

    let body = outline.iter().find(|i| i.node_type == "block").expect("block missing");
    assert_eq!(body.hint_key, Some("b"));
    assert_eq!(body.range.end_row, 2, "body end_row should be trimmed to last non-return child");
    assert_eq!(body.range.end_col, 18, "body end_col should be trimmed to last non-return child");

    let ret = outline.iter().find(|i| i.node_type == "return_statement").expect("return_statement missing");
    assert_eq!(ret.hint_key, Some("r"), "return_statement should be stamped with hint_key 'r'");
    assert_eq!(ret.range.start_row, 3);
    assert_eq!(ret.range.start_col, 2);
}

#[test]
fn function_declaration_without_return_shows_only_params_and_body() {
    // A function without a return statement should not add a return item to the outline.
    let fn_range = range(0, 0, 3, 3);
    let p_range  = range(0, 12, 0, 14);
    let b_range  = range(1, 0, 2, 3);

    let focus = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        // Snap 1: function_declaration focus — consumed by from_ancestry (node_snapshot).
        snap("function_declaration")
            .field_ranged("parameters", "()", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
            .field_ranged("block",      "...", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .child_ranged("parameters", "()", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
            .child_ranged("block",      "...", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .build(),
        // Snap 2: consumed by resolve_siblings_general (chunk fetch) — block snap is consumed
        // here; it yields no matching children so siblings resolve to (None, None). Then
        // enrich_function_outline's block fetch gets Err(NoNode) and returns early.
        snap("block")
            .child_ranged("variable_declaration", "local x = 1", 1, 2, 1, 14)
            .build(),
    ]).unwrap().unwrap();

    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "no return_statement means outline stays at two items");
    assert!(outline.iter().all(|i| i.node_type != "return_statement"));
}

// ── binary expression flattening ──────────────────────────────────────────

#[test]
fn binary_expression_outline_is_flattened_when_focused_directly() {
    // Focusing on a `binary_expression` should produce a flat outline of its operands.
    let be_range = range(0, 0, 0, 11);
    let a_range  = range(0, 0, 0, 1);
    let b_range  = range(0, 6, 0, 11);

    // binary_expression always has exactly 2 named children (left and right operands).
    let focus = NodeOutline { node_type: "binary_expression".into(), range: be_range.clone(), child_count: 2 };
    let root  = NodeOutline::new("chunk",             be_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        // Snap 1: binary_expression focus — consumed by from_ancestry.
        // The chunk fetch (resolve_siblings_general) and any further fetches get Err(NoNode).
        snap("binary_expression")
            .child_ranged("identifier", "a", a_range.start_row, a_range.start_col, a_range.end_row, a_range.end_col)
            .child_ranged("identifier", "b", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .build(),
    ]).unwrap().unwrap();

    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "should contain the two flat operands");
    assert_eq!(outline[0].node_type, "identifier");
    assert_eq!(outline[0].range.start_col, 0);
    assert_eq!(outline[1].node_type, "identifier");
    assert_eq!(outline[1].range.start_col, 6);
}
