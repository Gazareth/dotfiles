use crate::model::AtlantisNode;
use crate::model::resolved::AnyNode;
use crate::model::LuaNode;
use crate::tests::lua::*;

fn assert_loop(kind: &str) {
    let classified = lua(kind).classify();
    match classified {
        AtlantisNode::Recognised(AnyNode::Lua(LuaNode::Loop(_))) => {}
        other => panic!("expected '{kind}' to classify as Loop, got {other:?}"),
    }
}

#[test]
fn for_numeric_statement_classifies_as_loop() {
    assert_loop("for_numeric_statement");
}

#[test]
fn for_generic_statement_classifies_as_loop() {
    assert_loop("for_generic_statement");
}

#[test]
fn for_statement_classifies_as_loop() {
    assert_loop("for_statement");
}

#[test]
fn while_statement_classifies_as_loop() {
    assert_loop("while_statement");
}

#[test]
fn repeat_statement_classifies_as_loop() {
    assert_loop("repeat_statement");
}
