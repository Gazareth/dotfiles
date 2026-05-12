// Classification contract — BDD-style specs.
//
// Each test name states a rule. Tests are grouped by the rule they verify.
//
// Rule 1: A transparent node (ParameterList / ArgumentList / ExpressionList / Body)
//         with ≤ 1 named child returns Unrecognised — both the node itself and any
//         unrecognised token inside it. The walker climbs to the nearest meaningful parent.
//         Rationale: the only purpose of focusing a transparent node is to select a
//         specific child. With fewer than 2 children there is no selection to be made.
//
// Rule 2: A transparent node with 2+ named children is Recognised.
//         Each unrecognised token directly inside it is a Leaf — individually focusable
//         because each item has distinct identity.
//
// Leaf exceptions: tokens whose parent is a non-transparent non-list node (e.g. the name
//         identifier of a function_declaration) are never Leaf; they stay Unrecognised
//         and climb to the enclosing construct.

use crate::tests::lua::*;
use crate::survey::focused_node::FocusedNode;
use crate::survey::focused_node::ancestry::NodeAncestry;
use crate::probe::treesitter::NodeOutline;
use crate::probe::language::Language;
use crate::model::node::NodeRange;

fn range(sr: u32, sc: u32, er: u32, ec: u32) -> NodeRange {
    NodeRange { start_row: sr, start_col: sc, end_row: er, end_col: ec }
}

fn outline(node_type: &str, child_count: usize) -> NodeOutline {
    NodeOutline { node_type: node_type.into(), range: range(0, 0, 0, 10), child_count }
}

// ── Rule 1: single-child semi-transparent node collapses ──────────────────

#[test]
fn parameters_with_one_param_climbs_to_function_declaration() {
    // `parameters` node itself, child_count=1 → Unrecognised → climbs.
    let params = outline("parameters",          1);
    let func   = outline("function_declaration", 0);
    let root   = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![params, func], root, Language::Lua);

    snap("function_declaration").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration");
}

#[test]
fn identifier_inside_single_param_list_climbs_to_function_declaration() {
    // `x` cursor inside `parameters(1)` → Unrecognised → climbs past parameters → function.
    let ident  = outline("identifier",           0);
    let params = outline("parameters",           1);
    let func   = outline("function_declaration", 0);
    let root   = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![ident, params, func], root, Language::Lua);

    snap("function_declaration").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration");
}

#[test]
fn block_with_one_statement_climbs_to_enclosing_function() {
    // An unrecognised token inside a single-statement `block` climbs past the block.
    let token = outline("end",                   0);
    let block = outline("block",                 1);
    let func  = outline("function_declaration",  0);
    let root  = NodeOutline::new("chunk", range(0, 0, 5, 3));
    let ancestry = NodeAncestry::new_test(vec![token, block, func], root, Language::Lua);

    snap("function_declaration").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration");
}

#[test]
fn arguments_with_one_arg_climbs_to_function_call() {
    // `arguments` node itself (ExpressionList), child_count=1 → Unrecognised → climbs.
    let args = outline("arguments",    1);
    let call = outline("function_call", 0);
    let root = NodeOutline::new("chunk", range(0, 0, 0, 10));
    let ancestry = NodeAncestry::new_test(vec![args, call], root, Language::Lua);

    snap("function_call").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_call");
}

#[test]
fn identifier_inside_single_arg_list_climbs_to_function_call() {
    // `x` cursor inside `arguments(1)` → Unrecognised → climbs past arguments → call.
    let ident = outline("identifier",    0);
    let args  = outline("arguments",     1);
    let call  = outline("function_call", 0);
    let root  = NodeOutline::new("chunk", range(0, 0, 0, 10));
    let ancestry = NodeAncestry::new_test(vec![ident, args, call], root, Language::Lua);

    snap("function_call").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_call");
}

// ── Rule 2: multi-child semi-transparent node — items are Leaf ────────────

#[test]
fn parameters_with_multiple_params_is_recognised() {
    // `parameters` with 2 children is itself Recognised (focusable as a whole).
    let params = outline("parameters",           2);
    let func   = outline("function_declaration", 0);
    let root   = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![params, func], root, Language::Lua);

    snap("parameters").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "parameters");
}

#[test]
fn identifier_inside_multi_param_list_is_leaf() {
    // `x` cursor inside `parameters(2)` → Leaf (individually focusable).
    let ident  = outline("identifier",           0);
    let params = outline("parameters",           2);
    let func   = outline("function_declaration", 0);
    let root   = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![ident, params, func], root, Language::Lua);

    snap("identifier").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "identifier",
        "one of multiple params should be a Leaf focus target");
}

#[test]
fn identifier_inside_multi_statement_block_is_leaf() {
    // An unrecognised token inside a multi-statement `block` is a Leaf.
    let token = outline("end",                   0);
    let block = outline("block",                 2);
    let func  = outline("function_declaration",  0);
    let root  = NodeOutline::new("chunk", range(0, 0, 5, 3));
    let ancestry = NodeAncestry::new_test(vec![token, block, func], root, Language::Lua);

    snap("end").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "end",
        "token inside multi-statement block should remain as Leaf");
}

// ── Leaf exception: construct name identifiers are not Leaf ───────────────

#[test]
fn function_name_identifier_is_not_leaf() {
    // `foo` in `function foo(...)` — parent is function_declaration (Function kind,
    // not semi-transparent) so the identifier stays Unrecognised and climbs.
    let ident = outline("identifier",           0);
    let func  = outline("function_declaration", 0);
    let root  = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![ident, func], root, Language::Lua);

    snap("function_declaration").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration",
        "function name identifier should not be a Leaf; focus climbs to function_declaration");
}
