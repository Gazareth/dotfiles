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

// ── single-parameter function — outline redirect ─────────────────────────

#[test]
fn single_param_function_outline_redirects_parameters_item_to_identifier() {
    // When a function has exactly one parameter, the `parameters` outline item
    // should be redirected to the inner identifier so jumping lands on the parameter.
    let fn_range = range(0, 0, 4, 3);
    let p_range  = range(0, 12, 0, 15);  // "(x)"
    let x_range  = range(0, 13, 0, 14);  // "x"
    let b_range  = range(1, 0, 4, 3);

    let focus = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    // Snap 1: function_declaration focus — consumed by from_ancestry.
    snap("function_declaration")
        .field_ranged("parameters", "(x)",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .field_ranged("block",      "...",  b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .child_ranged("parameters", "(x)",  p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
        .child_ranged("block",      "...",  b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
        .queue();
    // Snap 2: chunk — consumed by resolve_siblings_general (sp snapshot).
    snap("chunk")
        .child_ranged("function_declaration", "...", fn_range.start_row, fn_range.start_col, fn_range.end_row, fn_range.end_col)
        .queue();
    // Snap 3: block (no return) — consumed by enrich_function_outline.
    // No children → no return_statement found → enrich returns early without adding return item.
    snap("block")
        .queue();
    // Snap 4: parameters — consumed by redirect_transparent_param_outline_item.
    snap("parameters")
        .child_ranged("identifier", "x", x_range.start_row, x_range.start_col, x_range.end_row, x_range.end_col)
        .queue();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    assert_eq!(outline.len(), 2, "should have two items (redirected param + block)");

    let param_item = outline.iter().find(|i| i.hint_key == Some("p")).expect("item with hint_key 'p' missing");
    assert_eq!(param_item.node_type, "identifier",
        "parameters item should be redirected to the inner identifier");
    assert_eq!(param_item.range.start_col, x_range.start_col,
        "redirected item range should point at the identifier, not the '(' of parameters");

    let body = outline.iter().find(|i| i.node_type == "block").expect("block missing");
    assert_eq!(body.hint_key, Some("b"));
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

// ── function_call ─────────────────────────────────────────────────────────

#[test]
fn function_call_outline_stamps_arguments_with_a() {
    // Focusing a function_call must stamp its `args` child (an ExpressionList /
    // arguments node) with hint_key 'a'. The function name identifier is suppressed
    // by outline_exceptions, so only the arguments item should remain.
    let call_range = range(0, 0, 0, 11); // print("hi")
    let name_range = range(0, 0, 0, 5);  // print
    let args_range = range(0, 5, 0, 11); // ("hi")

    let focus = NodeOutline::new("function_call", call_range.clone());
    let root  = NodeOutline::new("chunk",         call_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    snap("function_call")
        .field_ranged("name", "print",    name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
        .field_ranged("args", "(\"hi\")", args_range.start_row, args_range.start_col, args_range.end_row, args_range.end_col)
        .child_ranged("identifier", "print", name_range.start_row, name_range.start_col, name_range.end_row, name_range.end_col)
        .child_ranged("arguments",  "(\"hi\")", args_range.start_row, args_range.start_col, args_range.end_row, args_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    let args = outline.iter().find(|i| i.node_type == "arguments").expect("arguments missing");
    assert_eq!(args.hint_key, Some("a"), "arguments should get hint_key 'a'");
}

// ── if_statement (condition pinned to 't') ────────────────────────────────

#[test]
fn if_statement_outline_stamps_condition_with_t() {
    // Focusing an if_statement must stamp its `condition` child with hint_key 't'.
    // Consequence keeps 'b' and alternate (if present) keeps 'e'.
    // Use an identifier condition so binary_expression flattening doesn't kick in.
    let if_range   = range(0, 0, 4, 3);
    let cond_range = range(0, 3, 0, 4);  // x
    let body_range = range(1, 2, 3, 0);

    let focus = NodeOutline::new("if_statement", if_range.clone());
    let root  = NodeOutline::new("chunk",        if_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    snap("if_statement")
        .field_ranged("condition",   "x",   cond_range.start_row, cond_range.start_col, cond_range.end_row, cond_range.end_col)
        .field_ranged("consequence", "...", body_range.start_row, body_range.start_col, body_range.end_row, body_range.end_col)
        .child_ranged("identifier", "x",   cond_range.start_row, cond_range.start_col, cond_range.end_row, cond_range.end_col)
        .child_ranged("block",      "...", body_range.start_row, body_range.start_col, body_range.end_row, body_range.end_col)
        .inject();

    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    let outline = &result.outline;

    let cond = outline.iter()
        .find(|i| i.range.start_row == cond_range.start_row && i.range.start_col == cond_range.start_col)
        .expect("condition outline item missing");
    assert_eq!(cond.hint_key, Some("t"), "condition should get hint_key 't'");

    let body = outline.iter().find(|i| i.node_type == "block").expect("block missing");
    assert_eq!(body.hint_key, Some("b"), "consequence should keep hint_key 'b'");
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

    // Snap 1: variable_declaration focus — consumed by from_ancestry (node_snapshot).
    snap("variable_declaration")
        .child_ranged("assignment_statement", "x = 1",
            as_range.start_row, as_range.start_col, as_range.end_row, as_range.end_col)
        .queue();

    // Snap 2: chunk (semantic parent) — consumed by resolve_siblings_general.
    snap("chunk")
        .child_ranged("variable_declaration", "local x = 1",
            vd_range.start_row, vd_range.start_col, vd_range.end_row, vd_range.end_col)
        .queue();

    // Snap 3: assignment_statement — consumed during wrapper expansion.
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
