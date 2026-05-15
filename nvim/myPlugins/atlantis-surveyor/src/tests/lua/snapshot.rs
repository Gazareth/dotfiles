use crate::tests::lua::*;

#[test]
fn snapshot_converts_to_raw_node_and_classifies_correctly() {
    let s = snap("function_declaration").field_text("name", "add").build();
    let raw = crate::model::node::RawNode::from(&s);
    let f = crate::model::AtlantisNode::from_raw(raw, &crate::probe::language::Language::Lua)
        .as_function();

    assert_eq!(f.state.name, "add");
}
