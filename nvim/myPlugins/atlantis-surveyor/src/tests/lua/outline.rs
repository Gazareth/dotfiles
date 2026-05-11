// Outline suppression tests.

use crate::tests::lua::*;
use crate::survey::focused_node::FocusedNode;
use crate::survey::focused_node::ancestry::NodeAncestry;
use crate::probe::treesitter::NodeOutline;
use crate::probe::language::Language;
use crate::model::node::NodeRange;

fn range(sr: u32, sc: u32, er: u32, ec: u32) -> NodeRange {
    NodeRange { start_row: sr, start_col: sc, end_row: er, end_col: ec }
}

#[test]
fn function_declaration_outline_suppresses_name_identifier() {
    // A function declaration's name identifier should be suppressed from the outline.
    let fn_range = range(0, 0, 5, 3);
    let name_range = range(0, 9, 0, 12);  // `add`
    let p_range  = range(0, 12, 0, 18); // `(x, y)`
    let b_range  = range(1, 0, 4, 3);   // block

    let focus = NodeOutline { node_type: "function_declaration".into(), range: fn_range.clone() };
    let root  = NodeOutline { node_type: "chunk".into(), range: fn_range.clone() };
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Provide the snapshot
    snap("function_declaration")
        .field_ranged("name", "add", name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
        .field_ranged("parameters", "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .field_ranged("block", "...", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .child_ranged("identifier", "add", name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
        .child_ranged("parameters", "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block", "...", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "outline should have two items, the identifier should be suppressed");

    assert!(outline.iter().all(|i| i.node_type != "identifier"), "identifier should be suppressed");
    assert!(outline.iter().any(|i| i.node_type == "parameters"), "parameters should remain");
    assert!(outline.iter().any(|i| i.node_type == "block"), "block should remain");

    let body_item = outline.iter().find(|i| i.node_type == "block").unwrap();
    assert_eq!(body_item.hint_key, Some("b"), "Lua body (block) should be stamped with hint_key 'b'");
}
