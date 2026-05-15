// Classification contract — BDD-style specs.
//
// Each test name states a rule. Tests are grouped by the rule they verify.
//
// Terminology:
//   Translucent = an intrinsic node kind property (ParameterList, ArgumentList,
//                 ExpressionList, Body). Behaviour depends on child count and context.
//   Transparent = a translucent node instance that is invisible and climbed through:
//                 Guard B fires (≤1 child), or Guard C fires (same-type nesting).
//   Opaque      = a focusable, recognised node.
//
// Rule 1 (Guard B): A translucent node with ≤1 named child is transparent — both the
//         node itself and any unrecognised token inside it return Unrecognised.
//         The walker climbs to the nearest meaningful parent.
//
// Rule 2: A translucent node with 2+ named children is opaque (Recognised).
//         Each unrecognised token directly inside it is a Leaf — individually focusable.
//
// Rule 3 (Guard C): An ExpressionList node directly inside another node of the same
//         node_type is transparent, regardless of child count. This makes nested
//         binary_expression chains collapse naturally without bespoke flattening logic.
//
// Leaf exceptions: tokens whose parent is a non-translucent node (e.g. the name
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

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("function_declaration").build(),
    ]).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration");
}

#[test]
fn identifier_inside_single_param_list_is_focused_as_parameter() {
    // `x` cursor inside `parameters(1)` → Recognised(Parameter) → focused directly.
    // (Changed from "climbs to function_declaration" now that Guard A reclassifies
    //  identifier inside a 1-child ParameterList as Parameter.)
    let ident  = outline("identifier",           0);
    let params = outline("parameters",           1);
    let func   = outline("function_declaration", 0);
    let root   = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![ident, params, func], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("identifier").build(),
    ]).unwrap().unwrap();
    assert_eq!(result.node_type, "identifier",
        "identifier in single-param list is Recognised(Parameter) and should be focused directly");
}

#[test]
fn block_with_one_statement_climbs_to_enclosing_function() {
    // An unrecognised token inside a single-statement `block` climbs past the block.
    let token = outline("end",                   0);
    let block = outline("block",                 1);
    let func  = outline("function_declaration",  0);
    let root  = NodeOutline::new("chunk", range(0, 0, 5, 3));
    let ancestry = NodeAncestry::new_test(vec![token, block, func], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("function_declaration").build(),
    ]).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration");
}

#[test]
fn arguments_with_one_arg_climbs_to_function_call() {
    // `arguments` node itself (ExpressionList), child_count=1 → Unrecognised → climbs.
    let args = outline("arguments",    1);
    let call = outline("function_call", 0);
    let root = NodeOutline::new("chunk", range(0, 0, 0, 10));
    let ancestry = NodeAncestry::new_test(vec![args, call], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("function_call").build(),
    ]).unwrap().unwrap();
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

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("function_call").build(),
    ]).unwrap().unwrap();
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

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("parameters").build(),
    ]).unwrap().unwrap();
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

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("identifier").build(),
    ]).unwrap().unwrap();
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

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("end").build(),
    ]).unwrap().unwrap();
    assert_eq!(result.node_type, "end",
        "token inside multi-statement block should remain as Leaf");
}

// ── Leaf exception: construct name identifiers are not Leaf ───────────────

#[test]
fn function_name_identifier_is_not_leaf() {
    // `foo` in `function foo(...)` — parent is function_declaration (Function kind,
    // not translucent) so the identifier stays Unrecognised and climbs.
    let ident = outline("identifier",           0);
    let func  = outline("function_declaration", 0);
    let root  = NodeOutline::new("chunk", range(0, 0, 0, 20));
    let ancestry = NodeAncestry::new_test(vec![ident, func], root, Language::Lua);

    let result = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("function_declaration").build(),
    ]).unwrap().unwrap();
    assert_eq!(result.node_type, "function_declaration",
        "function name identifier should not be a Leaf; focus climbs to function_declaration");
}

// ── Single-param reclassification: identifier in 1-child ParameterList → Parameter ──

#[test]
fn identifier_inside_single_param_list_is_recognised_as_parameter() {
    // Guard A special case: a Lua identifier whose parent is a ParameterList with exactly
    // 1 child must be Recognised(Parameter), not Unrecognised — so it can be jumped to.
    use crate::model::node::RawNode;

    let params = outline("parameters", 1);
    let ident  = NodeOutline { node_type: "identifier".into(), range: range(0, 10, 0, 11), child_count: 0 };
    let lang   = Language::Lua;

    let classified = lang.classify(RawNode::from(&ident), Some(&params));
    assert!(
        matches!(classified, crate::model::AtlantisNode::Recognised(_)),
        "identifier inside 1-child ParameterList should be Recognised(Parameter), got {:?}", classified
    );
    assert_eq!(classified.classification_name(), "Parameter");
}

// ── Rule 3 (Guard C): ExpressionList inside same node_type is transparent ────

#[test]
fn inner_binary_expression_with_binary_expression_parent_is_unrecognised() {
    // Guard C: `binary_expression` directly inside `binary_expression` → transparent,
    // regardless of child count. The outermost binary_expression (whose parent is
    // expression_list, not binary_expression) remains Recognised (opaque).
    use crate::probe::language::Language;
    use crate::model::node::RawNode;

    let lang = Language::Lua;

    // Inner binary_expression — parent is also binary_expression.
    let inner_be = NodeOutline { node_type: "binary_expression".into(), range: range(0, 0, 0, 5), child_count: 2 };
    let outer_be = NodeOutline { node_type: "binary_expression".into(), range: range(0, 0, 0, 11), child_count: 2 };
    let classified = lang.classify(RawNode::from(&inner_be), Some(&outer_be));
    assert!(matches!(classified, crate::model::AtlantisNode::Unrecognised),
        "inner binary_expression inside binary_expression should be Unrecognised (Guard C)");

    // Outer binary_expression — parent is expression_list (not binary_expression) → opaque.
    let expr_list = NodeOutline { node_type: "expression_list".into(), range: range(0, 0, 0, 11), child_count: 1 };
    let classified_outer = lang.classify(RawNode::from(&outer_be), Some(&expr_list));
    assert!(matches!(classified_outer, crate::model::AtlantisNode::Recognised(_)),
        "outer binary_expression inside expression_list should be Recognised (opaque)");
}
