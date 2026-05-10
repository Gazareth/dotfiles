use crate::tests::lua::*;
use crate::survey::NavigationInfo;
use crate::probe::treesitter::{NodeOutline, NodeSnapshot};
use crate::probe::language::Language;

use crate::model::node::NodeRange;

const ZERO: NodeRange = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 0 };

#[test]
fn parent_navigation_can_target_containers() {
    // Structure: block -> variable_declaration -> assignment_statement
    // All starting at (1, 0)
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let r2 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 30 };
    let r3 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 40 };

    let assignment = NodeOutline { node_type: "assignment_statement".into(), range: r0.clone() };
    let variable   = NodeOutline { node_type: "variable_declaration".into(), range: r1.clone() };
    let block      = NodeOutline { node_type: "block".into(),                range: r2.clone() };
    let function   = NodeOutline { node_type: "function_declaration".into(), range: r3.clone() };

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
    assert_eq!(parent.node_type, "block");
}

#[test]
fn parent_navigation_skips_same_kind_constructs() {
    // Structure: variable_declaration -> assignment_statement
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let r2 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 30 };
    let assignment = NodeOutline { node_type: "assignment_statement".into(), range: r0.clone() };
    let variable   = NodeOutline { node_type: "variable_declaration".into(), range: r1.clone() };
    let function   = NodeOutline { node_type: "function_declaration".into(), range: r2.clone() };

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
    assert_eq!(parent.node_type, "function_declaration");
}

#[test]
fn parent_navigation_jumps_across_different_construct_kinds() {
    // Structure: function_declaration -> variable_declaration -> function_call
    // Kinds: Function -> Assignment -> Call
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let r2 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 30 };

    let call     = NodeOutline { node_type: "function_call".into(),        range: r0.clone() };
    let variable = NodeOutline { node_type: "variable_declaration".into(), range: r1.clone() };
    let function = NodeOutline { node_type: "function_declaration".into(), range: r2.clone() };

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
    assert_eq!(parent.node_type, "variable_declaration");
}

#[test]
fn parent_navigation_jumps_from_assignment_to_conditional() {
    // Structure: if_statement -> assignment_statement
    // Kinds: Conditional -> Assignment
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };

    let assignment  = NodeOutline { node_type: "assignment_statement".into(), range: r0.clone() };
    let conditional = NodeOutline { node_type: "if_statement".into(),         range: r1.clone() };

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
    assert_eq!(parent.node_type, "if_statement");
}



#[test]
fn from_ancestry_returns_unsupported_language_when_no_node_matches() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;

    // Structure: some unknown nodes
    let r0 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let r1 = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 20 };
    let unknown = NodeOutline { node_type: "comment".into(),      range: r0.clone() };
    let root    = NodeOutline { node_type: "unknown_root".into(), range: r1.clone() };

    let ancestry = NodeAncestry::new_test(vec![unknown], root, Language::Lua);

    // Lua doesn't classify 'comment' or 'unknown_root' as Recognised
    let result = FocusedNode::from_ancestry(ancestry, None);

    match result {
        Ok(None) => {}, // Changed: it now safely returns Ok(None) when focus index is not found
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
    let local_kw = NodeOutline { node_type: "local".into(), range: range.clone() };
    let func_decl = NodeOutline { node_type: "function_declaration".into(), range: range.clone() };
    let root = NodeOutline { node_type: "chunk".into(), range: range.clone() };

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
    let ident = NodeOutline { node_type: "identifier".into(), range: range.clone() };
    let expr_list = NodeOutline { node_type: "expression_list".into(), range: range.clone() };
    let root = NodeOutline { node_type: "chunk".into(), range: range.clone() };

    let ancestry = NodeAncestry::new_test(vec![ident, expr_list], root, Language::Lua);

    crate::tests::helpers::snap("identifier").inject();
    let result = FocusedNode::from_ancestry(ancestry, None).unwrap().unwrap();
    // It should stop at identifier as a Leaf, because expression_list is a transparent container
    assert_eq!(result.node_type, "identifier");
}
