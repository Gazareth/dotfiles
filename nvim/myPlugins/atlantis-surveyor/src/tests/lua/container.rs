use crate::tests::lua::*;

#[test]
fn container_nodes_classify_correctly() {
    assert!(matches!(lua("chunk")     .classify().as_node(), LuaNode::FileRoot(_)));
    assert!(matches!(lua("block")     .classify().as_node(), LuaNode::Body(_)));
    assert!(matches!(lua("parameters").classify().as_node(), LuaNode::ParameterList(_)));
}
