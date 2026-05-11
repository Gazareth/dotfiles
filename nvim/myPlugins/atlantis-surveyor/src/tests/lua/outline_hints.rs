// Outline hint_key stamping tests.
//
// Verifies that OutlineItem.hint_key is correctly stamped based on the keyed
// NavigationTarget fields of the focused node, including the wrapper-expansion
// path for nodes like `variable_declaration` whose outline initially contains
// a transparent `assignment_statement` child.

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
fn function_outline_parameters_gets_p_hint_key() {
    // function_declaration whose outline has two children: parameters and block.
    // parameters NavigationTarget (from field) and outline child share the same range.
    let fn_range  = range(0, 0, 5, 3);
    let p_range   = range(0, 10, 0, 16);  // `(x, y)`
    let b_range   = range(1, 0, 4, 3);    // block

    let focus = NodeOutline { node_type: "function_declaration".into(), range: fn_range.clone() };
    let root  = NodeOutline { node_type: "chunk".into(), range: fn_range.clone() };
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Snapshot used for both classification (fields) and outline (children).
    snap("function_declaration")
        .field("name", "add")
        .field_ranged("parameters", "(x, y)", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .field_ranged("block", "...",           b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .child_ranged("parameters", "(x, y)",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block", "...",           b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "should have two outline items");

    let params_item = outline.iter().find(|i| i.node_type == "parameters")
        .expect("parameters outline item missing");
    assert_eq!(params_item.hint_key, Some("p"), "parameters should get hint_key 'p'");

    let body_item = outline.iter().find(|i| i.node_type == "block")
        .expect("block outline item missing");
    assert_eq!(body_item.hint_key, Some("b"), "block should get hint_key 'b'");
}

// ── assignment_statement ──────────────────────────────────────────────────

#[test]
fn assignment_outline_stamps_n_on_lhs_and_v_on_value() {
    // assignment_statement: `x = 1 + 2`
    // children: variable_list at col 0, expression_list at col 4.
    let a_range  = range(0, 0, 0, 9);
    let lhs_range = range(0, 0, 0, 1);  // `x`
    let val_range = range(0, 4, 0, 9);  // `1 + 2`

    let focus = NodeOutline { node_type: "assignment_statement".into(), range: a_range.clone() };
    let root  = NodeOutline { node_type: "chunk".into(), range: a_range.clone() };
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    snap("assignment_statement")
        .child_ranged("variable_list",    "x",     lhs_range.start_row, lhs_range.start_col, lhs_range.end_row, lhs_range.end_col)
        .child_ranged("expression_list",  "1 + 2", val_range.start_row, val_range.start_col, val_range.end_row, val_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "should have two outline items");

    let lhs_item = outline.iter().find(|i| i.node_type == "variable_list")
        .expect("variable_list outline item missing");
    assert_eq!(lhs_item.hint_key, Some("n"), "variable_list should get hint_key 'n'");

    let val_item = outline.iter().find(|i| i.node_type == "expression_list")
        .expect("expression_list outline item missing");
    assert_eq!(val_item.hint_key, Some("v"), "expression_list should get hint_key 'v'");
}

// ── variable_declaration (wrapper expansion) ──────────────────────────────

#[test]
fn variable_declaration_wrapper_is_expanded_and_hints_stamped() {
    // `local x = 1`
    // Lua grammar: variable_declaration( assignment_statement( variable_list, expression_list ) )
    // The outline of variable_declaration initially contains ONE item: assignment_statement.
    // The lhs hint shares assignment_statement's start (col 6), the value hint is at col 10.
    // The post-processor must expand the wrapper and stamp both grandchildren.
    //
    // Positions (col offsets after "local "):
    //   assignment_statement: cols 6..12  ("x = 1")
    //   variable_list:        cols 6..7   ("x")
    //   expression_list:      cols 10..11 ("1")
    //
    // value hint offset calculation: "x = 1".find('=') = 2, rhs = "1", offset = 5-1 = 4
    //   → value.start_col = 6 + 4 = 10  ✓

    let vd_range   = range(0, 0, 0, 12);
    let as_range   = range(0, 6, 0, 12);  // assignment_statement range
    let vl_range   = range(0, 6, 0, 7);   // variable_list range
    let el_range   = range(0, 10, 0, 11); // expression_list range

    let focus = NodeOutline { node_type: "variable_declaration".into(), range: vd_range.clone() };
    let root  = NodeOutline { node_type: "chunk".into(), range: vd_range.clone() };
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Queue snapshot 1: variable_declaration — single child is assignment_statement.
    snap("variable_declaration")
        .child_ranged("assignment_statement", "x = 1",
            as_range.start_row, as_range.start_col, as_range.end_row, as_range.end_col)
        .queue();

    // Queue snapshot 2: assignment_statement — expanded grandchildren for hint stamping.
    snap("assignment_statement")
        .child_ranged("variable_list",   "x",
            vl_range.start_row, vl_range.start_col, vl_range.end_row, vl_range.end_col)
        .child_ranged("expression_list", "1",
            el_range.start_row, el_range.start_col, el_range.end_row, el_range.end_col)
        .queue();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 1, "wrapper should not be expanded anymore");
    assert_eq!(outline[0].node_type, "assignment_statement");
    assert_eq!(outline[0].hint_key, Some("n"), "lhs hint should be stamped on the assignment node");
}
// ── binary expression flattening ──────────────────────────────────────────

#[test]
fn binary_expression_outline_is_flattened_when_focused_directly() {
    // Focusing on a `binary_expression` node should produce a flat outline of
    // its operands, not a single nested binary_expression child.
    //
    // AST for `a and b`:
    //   binary_expression
    //     identifier: a  (col 0)
    //     identifier: b  (col 6)
    let be_range = range(0, 0, 0, 11);
    let a_range  = range(0, 0, 0, 1);
    let b_range  = range(0, 6, 0, 11);

    let focus = NodeOutline { node_type: "binary_expression".into(), range: be_range.clone() };
    let root  = NodeOutline { node_type: "chunk".into(), range: be_range.clone() };
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Snapshot 1: the binary_expression focus node — children are the two operands.
    snap("binary_expression")
        .child_ranged("identifier", "a", a_range.start_row, a_range.start_col, a_range.end_row, a_range.end_col)
        .child_ranged("identifier", "b", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2,
        "binary_expression outline should contain the two flat operands, not a nested wrapper");
    assert_eq!(outline[0].node_type, "identifier");
    assert_eq!(outline[0].range.start_col, 0);
    assert_eq!(outline[1].node_type, "identifier");
    assert_eq!(outline[1].range.start_col, 6);
}

#[test]
fn expression_list_with_binary_child_is_flattened() {
    // This is the regression case: an `expression_list` whose sole child is a
    // `binary_expression`. Before the fix, Atlantis showed [binary_expression]
    // as a single dead-end outline item instead of flattening to operands.
    //
    // AST for `a and b` assigned as a value:
    //   expression_list
    //     binary_expression
    //       identifier: a  (col 0)
    //       identifier: b  (col 6)
    let el_range = range(0, 0, 0, 11);
    let be_range = range(0, 0, 0, 11);  // same span as expression_list
    let a_range  = range(0, 0, 0, 1);
    let b_range  = range(0, 6, 0, 11);

    let focus = NodeOutline { node_type: "expression_list".into(), range: el_range.clone() };
    let root  = NodeOutline { node_type: "chunk".into(), range: el_range.clone() };
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Snapshot 1: expression_list — one child: binary_expression.
    snap("expression_list")
        .child_ranged("binary_expression", "a and b",
            be_range.start_row, be_range.start_col, be_range.end_row, be_range.end_col)
        .queue();

    // Snapshot 2: binary_expression — its two operands.
    // flatten_binary_outline will request this snapshot when expanding the child.
    snap("binary_expression")
        .child_ranged("identifier", "a", a_range.start_row, a_range.start_col, a_range.end_row, a_range.end_col)
        .child_ranged("identifier", "b", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .queue();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2,
        "expression_list outline should flatten through binary_expression to show the two operands");
    assert!(outline.iter().all(|i| i.node_type != "binary_expression"),
        "no binary_expression items should remain in the flattened outline");
    assert_eq!(outline[0].node_type, "identifier");
    assert_eq!(outline[0].range.start_col, 0, "first operand 'a'");
    assert_eq!(outline[1].node_type, "identifier");
    assert_eq!(outline[1].range.start_col, 6, "second operand 'b'");
}
