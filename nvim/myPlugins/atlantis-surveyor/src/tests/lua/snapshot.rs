use crate::tests::lua::*;
use crate::probe::treesitter;

#[test]
fn returns_error_when_nothing_is_injected() {
    treesitter::clear_snapshot();
    assert!(treesitter::snapshot(0, 0, None, None).is_err());
}

#[test]
fn injected_snapshot_is_returned_by_next_call() {
    snap("function_declaration").field("name", "add").inject();

    let returned = treesitter::snapshot(0, 0, None, None)
        .expect("should return the injected snapshot");

    assert_eq!(returned.node_type, "function_declaration");
    treesitter::clear_snapshot();
}

#[test]
fn snapshot_converts_to_raw_node_and_classifies_correctly() {
    let s = snap("function_declaration").field("name", "add").build();
    let raw = crate::model::node::RawNode::from(&s);
    let f = crate::model::AtlantisNode::from_raw(raw, &crate::probe::language::Language::Lua)
        .as_function();

    assert_eq!(f.state.name, "add");
}
