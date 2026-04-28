use serde::Serialize;

use crate::model::lang::languages::{
    JavaScriptContainerNode, JavaScriptNode,
    LuaContainerNode, LuaNode,
    PythonContainerNode, PythonNode,
    TypeScriptContainerNode, TypeScriptNode,
};

/// Any language's resolved Standard node.
#[derive(Debug, Serialize)]
#[serde(tag = "lang", content = "node", rename_all = "snake_case")]
pub enum AnyStandardNode {
    Lua(LuaNode),
    JavaScript(JavaScriptNode),
    TypeScript(TypeScriptNode),
    Python(PythonNode),
}

/// Any language's resolved Container node.
#[derive(Debug, Serialize)]
#[serde(tag = "lang", content = "node", rename_all = "snake_case")]
pub enum AnyContainerNode {
    Lua(LuaContainerNode),
    JavaScript(JavaScriptContainerNode),
    TypeScript(TypeScriptContainerNode),
    Python(PythonContainerNode),
}
