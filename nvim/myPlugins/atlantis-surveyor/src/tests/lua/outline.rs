// Outline composition tests.

use crate::tests::lua::*;
use crate::survey::focused_node::FocusedNode;
use crate::survey::focused_node::ancestry::NodeAncestry;
use crate::probe::treesitter::NodeOutline;
use crate::probe::language::Language;
use crate::model::node::NodeRange;

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

    snap("function_declaration")
        .field_ranged("name",       "add",    name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
        .field_ranged("parameters", "(x, y)", p_range.start_row,    p_range.start_col,    p_range.end_row,    p_range.end_col)
        .field_ranged("block",      "...",    b_range.start_row,    b_range.start_col,    b_range.end_row,    b_range.end_col)
        .child_ranged("identifier", "add",    name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
        .child_ranged("parameters", "(x, y)", p_range.start_row,    p_range.start_col,    p_range.end_row,    p_range.end_col)
        .child_ranged("block",      "...",    b_range.start_row,    b_range.start_col,    b_range.end_row,    b_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "identifier should be suppressed, leaving two items");
    assert!(outline.iter().all(|i| i.node_type != "identifier"), "identifier should be suppressed");
    assert!(outline.iter().any(|i| i.node_type == "parameters"), "parameters should remain");
    assert!(outline.iter().any(|i| i.node_type == "block"), "block should remain");

    let body = outline.iter().find(|i| i.node_type == "block").unwrap();
    assert_eq!(body.hint_key, Some("b"), "block should be stamped with hint_key 'b'");
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

    snap("binary_expression")
        .child_ranged("identifier", "a", a_range.start_row, a_range.start_col, a_range.end_row, a_range.end_col)
        .child_ranged("identifier", "b", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "should contain the two flat operands");
    assert_eq!(outline[0].node_type, "identifier");
    assert_eq!(outline[0].range.start_col, 0);
    assert_eq!(outline[1].node_type, "identifier");
    assert_eq!(outline[1].range.start_col, 6);
}
