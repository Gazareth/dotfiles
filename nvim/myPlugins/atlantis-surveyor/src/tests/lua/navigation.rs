use crate::tests::lua::*;
use crate::survey::NavigationInfo;
use crate::probe::treesitter::{NodeOutline, NodeSnapshot};
use crate::model::FocusMode;
use crate::model::node::NodeRange;

const ZERO: NodeRange = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 0 };

#[test]
fn parent_navigation_can_target_containers_with_correct_mode() {
    // Structure: block -> variable_declaration -> assignment_statement
    // All starting at (1, 0)
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    
    let assignment = NodeOutline { node_type: "assignment_statement".into(), range: range.clone() };
    let variable   = NodeOutline { node_type: "variable_declaration".into(), range: range.clone() };
    let block      = NodeOutline { node_type: "block".into(),                range: range.clone() };
    let function   = NodeOutline { node_type: "function_declaration".into(), range: range.clone() };

    let all = vec![&assignment, &variable, &block, &function];
    let snapshot = NodeSnapshot {
        node_type: "variable_declaration".into(),
        text: "".into(),
        range: range.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    // Focus is variable_declaration (idx 1)
    let nav = NavigationInfo::resolve(&all, 1, &snapshot, |raw| {
        lua(&raw.kind).classify()
    });

    // Parent should be the block (idx 2) and it should have target_mode: Container
    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "block");
    assert_eq!(parent.target_mode, FocusMode::Container);
}

#[test]
fn parent_navigation_skips_same_kind_constructs() {
    // Structure: variable_declaration -> assignment_statement
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let assignment = NodeOutline { node_type: "assignment_statement".into(), range: range.clone() };
    let variable   = NodeOutline { node_type: "variable_declaration".into(), range: range.clone() };
    let function   = NodeOutline { node_type: "function_declaration".into(), range: range.clone() };

    let all = vec![&assignment, &variable, &function];
    let snapshot = NodeSnapshot {
        node_type: "assignment_statement".into(),
        text: "".into(),
        range: range.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    // Focus is assignment_statement (idx 0)
    let nav = NavigationInfo::resolve(&all, 0, &snapshot, |raw| {
        lua(&raw.kind).classify()
    });

    // Parent should skip variable_declaration (same class: Assignment) and go to function_declaration
    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "function_declaration");
    assert_eq!(parent.target_mode, FocusMode::Construct);
}

#[test]
fn parent_navigation_jumps_across_different_construct_kinds() {
    // Structure: function_declaration -> variable_declaration -> function_call
    // Kinds: Function -> Assignment -> Call
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    
    let call     = NodeOutline { node_type: "function_call".into(),        range: range.clone() };
    let variable = NodeOutline { node_type: "variable_declaration".into(), range: range.clone() };
    let function = NodeOutline { node_type: "function_declaration".into(), range: range.clone() };

    let all = vec![&call, &variable, &function];
    let snapshot = NodeSnapshot {
        node_type: "function_call".into(),
        text: "".into(),
        range: range.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    // Focus is function_call (idx 0)
    let nav = NavigationInfo::resolve(&all, 0, &snapshot, |raw| {
        lua(&raw.kind).classify()
    });

    // Parent should be variable_declaration (different kind: Assignment vs Call)
    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "variable_declaration");
    assert_eq!(parent.target_mode, FocusMode::Construct);
}

#[test]
fn parent_navigation_jumps_from_assignment_to_conditional() {
    // Structure: if_statement -> assignment_statement
    // Kinds: Conditional -> Assignment
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    
    let assignment  = NodeOutline { node_type: "assignment_statement".into(), range: range.clone() };
    let conditional = NodeOutline { node_type: "if_statement".into(),         range: range.clone() };

    let all = vec![&assignment, &conditional];
    let snapshot = NodeSnapshot {
        node_type: "assignment_statement".into(),
        text: "".into(),
        range: range.clone(),
        fields: Default::default(),
        children: vec![],
        siblings: vec![],
    };

    let nav = NavigationInfo::resolve(&all, 0, &snapshot, |raw| {
        lua(&raw.kind).classify()
    });

    let parent = nav.parent.expect("should have a parent");
    assert_eq!(parent.node_type, "if_statement");
    assert_eq!(parent.target_mode, FocusMode::Construct);
}

#[test]
fn focus_mode_filtering_skips_construct_when_in_container_mode() {
    use crate::survey::focused_node::FocusedNode;
    use crate::survey::focused_node::ancestry::NodeAncestry;
    use crate::probe::language::Language;

    // Structure: block -> variable_declaration
    let range = NodeRange { start_row: 1, start_col: 0, end_row: 1, end_col: 10 };
    let variable = NodeOutline { node_type: "variable_declaration".into(), range: range.clone() };
    let block    = NodeOutline { node_type: "block".into(),                range: range.clone() };
    let root     = NodeOutline { node_type: "chunk".into(),                range: range.clone() };

    let ancestry = NodeAncestry::new_test(vec![variable, block], root, Language::Lua);

    // If we ask for Construct, we should get variable_declaration
    snap("variable_declaration").inject();
    let focus_construct = FocusedNode::from_ancestry(ancestry.clone(), FocusMode::Construct)
        .expect("should find a focus");
    assert_eq!(focus_construct.node_type, "variable_declaration");

    // If we ask for Container, we should skip variable_declaration and get block
    snap("block").inject();
    let focus_container = FocusedNode::from_ancestry(ancestry, FocusMode::Container)
        .expect("should find a focus");
    assert_eq!(focus_container.node_type, "block");
}
