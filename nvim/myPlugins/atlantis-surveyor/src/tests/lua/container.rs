use crate::tests::lua::*;

#[test]
fn container_nodes_classify_correctly() {
    assert!(matches!(lua("chunk")     .classify().as_container(), LuaContainerNode::FileRoot(_)));
    assert!(matches!(lua("block")     .classify().as_container(), LuaContainerNode::Body(_)));
    assert!(matches!(lua("parameters").classify().as_container(), LuaContainerNode::ParameterList(_)));
}
