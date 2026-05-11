mod assignment;
mod conditional;
mod container;
mod function;
mod snapshot;
mod navigation;
mod outline_hints;
pub mod outline;

pub use super::helpers::*;
pub use crate::model::AtlantisNode;
pub use crate::model::resolved::AnyNode;
pub use crate::model::LuaNode;

pub trait AsLuaNode: Sized {
    type Function;
    type Assignment;
    type Conditional;
    type Call;

    fn as_function   (self) -> Self::Function;
    fn as_assignment (self) -> Self::Assignment;
    fn as_conditional(self) -> Self::Conditional;
    fn as_call       (self) -> Self::Call;
    fn as_node       (self) -> LuaNode;
    fn is_unrecognised(self) -> bool;
}

impl AsLuaNode for AtlantisNode {
    type Function    = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::FunctionDeclaration>;
    type Assignment  = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::Assignment>;
    type Conditional = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::ConditionalStatement>;
    type Call        = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::FunctionCall>;

    fn as_function(self) -> Self::Function {
        match self { AtlantisNode::Recognised(AnyNode::Lua(LuaNode::Function(n))) => n,
            o => panic!("expected Function, got {o:?}") }
    }
    fn as_assignment(self) -> Self::Assignment {
        match self { AtlantisNode::Recognised(AnyNode::Lua(LuaNode::Assignment(n))) => n,
            o => panic!("expected Assignment, got {o:?}") }
    }
    fn as_conditional(self) -> Self::Conditional {
        match self { AtlantisNode::Recognised(AnyNode::Lua(LuaNode::Conditional(n))) => n,
            o => panic!("expected Conditional, got {o:?}") }
    }
    fn as_call(self) -> Self::Call {
        match self { AtlantisNode::Recognised(AnyNode::Lua(LuaNode::Call(n))) => n,
            o => panic!("expected Call, got {o:?}") }
    }
    fn as_node(self) -> LuaNode {
        match self { AtlantisNode::Recognised(AnyNode::Lua(c)) => c,
            o => panic!("expected LuaNode, got {o:?}") }
    }
    fn is_unrecognised(self) -> bool { matches!(self, AtlantisNode::Unrecognised) }
}

// ── Cross-cutting: unrecognised / unsupported language ────────────────────

#[test]
fn unsupported_lua_kinds_produce_unrecognised() {
    for kind in ["comment", "string", "do_statement"] {
        assert!(lua(kind).classify().is_unrecognised(), "'{kind}' should be Unrecognised");
    }
}

#[test]
fn unknown_language_always_produces_unrecognised() {
    for kind in ["function_declaration", "chunk", "if_statement"] {
        assert!(unknown(kind).classify().is_unrecognised(),
            "'{kind}' should be Unrecognised for Language::Unknown");
    }
}
