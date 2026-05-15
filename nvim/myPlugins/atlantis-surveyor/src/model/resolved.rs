use serde::Serialize;

use crate::action::ConstructActions;
use crate::model::lang::languages::{
    JavaScriptNode,
    LuaNode,
    PythonNode,
    TypeScriptNode,
};

/// Any language's resolved node.
#[derive(Debug, Serialize, Clone)]
#[serde(tag = "lang", content = "node", rename_all = "snake_case")]
pub enum AnyNode {
    Lua(LuaNode),
    JavaScript(JavaScriptNode),
    TypeScript(TypeScriptNode),
    Python(PythonNode),
}

impl AnyNode {
    pub fn available_actions(&self) -> &'static [&'static str] {
        match self {
            AnyNode::Lua(n)        => n.available_actions(),
            AnyNode::JavaScript(n) => n.available_actions(),
            AnyNode::TypeScript(n) => n.available_actions(),
            AnyNode::Python(n)     => n.available_actions(),
        }
    }

    pub fn keyed_outline_hints(&self) -> Vec<(crate::model::node::NodeRange, &'static str)> {
        match self {
            AnyNode::Lua(n)        => n.keyed_outline_hints(),
            AnyNode::JavaScript(n) => n.keyed_outline_hints(),
            AnyNode::TypeScript(n) => n.keyed_outline_hints(),
            AnyNode::Python(n)     => n.keyed_outline_hints(),
        }
    }



    pub fn outline_exceptions(&self) -> Vec<crate::model::node::NodeRange> {
        match self {
            AnyNode::Lua(n)        => n.outline_exceptions(),
            AnyNode::JavaScript(n) => n.outline_exceptions(),
            AnyNode::TypeScript(n) => n.outline_exceptions(),
            AnyNode::Python(n)     => n.outline_exceptions(),
        }
    }

    pub fn node_type_name(&self) -> &'static str {
        match self {
            AnyNode::Lua(n)        => n.node_type_name(),
            AnyNode::JavaScript(n) => n.node_type_name(),
            AnyNode::TypeScript(n) => n.node_type_name(),
            AnyNode::Python(n)     => n.node_type_name(),
        }
    }
}
