use serde::Serialize;

use crate::action::ConstructActions;
use crate::model::lang::languages::{
    JavaScriptContainerNode, JavaScriptNode,
    LuaContainerNode, LuaNode,
    PythonContainerNode, PythonNode,
    TypeScriptContainerNode, TypeScriptNode,
};

/// Any language's resolved Construct node.
#[derive(Debug, Serialize, Clone)]
#[serde(tag = "lang", content = "node", rename_all = "snake_case")]
pub enum AnyConstructNode {
    Lua(LuaNode),
    JavaScript(JavaScriptNode),
    TypeScript(TypeScriptNode),
    Python(PythonNode),
}

impl AnyConstructNode {
    pub fn available_actions(&self) -> &'static [&'static str] {
        match self {
            AnyConstructNode::Lua(n)        => n.available_actions(),
            AnyConstructNode::JavaScript(n) => n.available_actions(),
            AnyConstructNode::TypeScript(n) => n.available_actions(),
            AnyConstructNode::Python(n)     => n.available_actions(),
        }
    }

    pub fn node_type_name(&self) -> &'static str {
        match self {
            AnyConstructNode::Lua(n)        => n.node_type_name(),
            AnyConstructNode::JavaScript(n) => n.node_type_name(),
            AnyConstructNode::TypeScript(n) => n.node_type_name(),
            AnyConstructNode::Python(n)     => n.node_type_name(),
        }
    }
}

/// Any language's resolved Container node.
#[derive(Debug, Serialize, Clone)]
#[serde(tag = "lang", content = "node", rename_all = "snake_case")]
pub enum AnyContainerNode {
    Lua(LuaContainerNode),
    JavaScript(JavaScriptContainerNode),
    TypeScript(TypeScriptContainerNode),
    Python(PythonContainerNode),
}

impl AnyContainerNode {
    pub fn node_type_name(&self) -> &'static str {
        match self {
            AnyContainerNode::Lua(n)        => n.node_type_name(),
            AnyContainerNode::JavaScript(n) => n.node_type_name(),
            AnyContainerNode::TypeScript(n) => n.node_type_name(),
            AnyContainerNode::Python(n)     => n.node_type_name(),
        }
    }
}
