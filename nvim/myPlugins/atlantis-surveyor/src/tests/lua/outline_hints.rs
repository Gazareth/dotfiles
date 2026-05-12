// Outline hint_key stamping tests.
//
// Verifies that OutlineItem.hint_key is correctly stamped based on the keyed
// NavigationTarget fields of the focused node.

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
fn function_outline_shows_only_parameters_and_body() {
    // Focusing a function_declaration must produce exactly [parameters(p), block(b)].
    let fn_range = range(0, 0, 5, 3);
    let p_range  = range(0, 10, 0, 16);
    let b_range  = range(1, 0, 4, 3);

    let focus = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    snap("function_declaration")
        .field_text("name", "add")
        .field_ranged("parameters", "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .field_ranged("block", "...",          b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .child_ranged("parameters", "(x, y)",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block", "...",           b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "outline should have exactly two items");

    let params = outline.iter().find(|i| i.node_type == "parameters").expect("parameters missing");
    assert_eq!(params.hint_key, Some("p"), "parameters should get hint_key 'p'");

    let body = outline.iter().find(|i| i.node_type == "block").expect("block missing");
    assert_eq!(body.hint_key, Some("b"), "block should get hint_key 'b'");
}

// ── assignment_statement ──────────────────────────────────────────────────

#[test]
fn assignment_statement_outline_shows_only_name_and_value() {
    // Focusing an assignment_statement must produce exactly [variable_list(n), expression_list(v)].
    let a_range   = range(0, 0, 0, 9);
    let lhs_range = range(0, 0, 0, 1);
    let val_range = range(0, 4, 0, 9);

    let focus = NodeOutline::new("assignment_statement", a_range.clone());
    let root  = NodeOutline::new("chunk",                a_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    snap("assignment_statement")
        .child_ranged("variable_list",   "x",     lhs_range.start_row, lhs_range.start_col, lhs_range.end_row, lhs_range.end_col)
        .child_ranged("expression_list", "1 + 2", val_range.start_row, val_range.start_col, val_range.end_row, val_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "outline should have exactly two items");

    let lhs = outline.iter().find(|i| i.node_type == "variable_list").expect("variable_list missing");
    assert_eq!(lhs.hint_key, Some("n"), "variable_list should get hint_key 'n'");

    let val = outline.iter().find(|i| i.node_type == "expression_list").expect("expression_list missing");
    assert_eq!(val.hint_key, Some("v"), "expression_list should get hint_key 'v'");
}

// ── variable_declaration ──────────────────────────────────────────────────

#[test]
fn variable_declaration_outline_shows_only_name_and_value() {
    // Focusing a variable_declaration must also produce exactly [something(n), something(v)].
    //
    // Lua grammar: variable_declaration( assignment_statement( variable_list, expression_list ) )
    // The outline post-processor expands the transparent assignment_statement wrapper.
    //
    // `local x = 1` layout:
    //   assignment_statement: col 6..12  ("x = 1")
    //   variable_list:        col 6..7   ("x")
    //   expression_list:      col 10..11 ("1")  [col 6 + len("x = ") = 10]
    let vd_range = range(0, 0, 0, 12);
    let as_range = range(0, 6, 0, 12);
    let vl_range = range(0, 6, 0, 7);
    let el_range = range(0, 10, 0, 11);

    let focus = NodeOutline::new("variable_declaration", vd_range.clone());
    let root  = NodeOutline::new("chunk",                vd_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Snapshot 1: variable_declaration — single child is assignment_statement.
    snap("variable_declaration")
        .child_ranged("assignment_statement", "x = 1",
            as_range.start_row, as_range.start_col, as_range.end_row, as_range.end_col)
        .queue();

    // Snapshot 2: assignment_statement — its children (consumed during wrapper expansion).
    snap("assignment_statement")
        .child_ranged("variable_list",   "x",
            vl_range.start_row, vl_range.start_col, vl_range.end_row, vl_range.end_col)
        .child_ranged("expression_list", "1",
            el_range.start_row, el_range.start_col, el_range.end_row, el_range.end_col)
        .queue();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "outline should have exactly two items after wrapper expansion");

    let name_item = outline.iter().find(|i| i.node_type == "variable_list").expect("variable_list missing");
    assert_eq!(name_item.hint_key, Some("n"), "variable_list should get hint_key 'n'");

    let val_item = outline.iter().find(|i| i.node_type == "expression_list").expect("expression_list missing");
    assert_eq!(val_item.hint_key, Some("v"), "expression_list should get hint_key 'v'");
}
