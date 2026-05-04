mod assignment;
mod conditional;
mod container;
mod function;
mod snapshot;

pub use super::helpers::*;
pub use crate::model::AtlantisNode;
pub use crate::model::resolved::{AnyConstructNode, AnyContainerNode};
pub use crate::model::{LuaNode, LuaContainerNode};

pub trait AsLuaNode: Sized {
    type Function;
    type Assignment;
    type Conditional;
    type Call;

    fn as_function   (self) -> Self::Function;
    fn as_assignment (self) -> Self::Assignment;
    fn as_conditional(self) -> Self::Conditional;
    fn as_call       (self) -> Self::Call;
    fn as_container  (self) -> LuaContainerNode;
    fn is_unrecognised(self) -> bool;
}

impl AsLuaNode for AtlantisNode {
    type Function    = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::FunctionDeclaration>;
    type Assignment  = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::Assignment>;
    type Conditional = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::ConditionalStatement>;
    type Call        = crate::model::node::Node<crate::model::lang::languages::lua::Lua, crate::model::supported_nodes::standard::FunctionCall>;

    fn as_function(self) -> Self::Function {
        match self { AtlantisNode::Construct(AnyConstructNode::Lua(LuaNode::Function(n))) => n,
            o => panic!("expected Function, got {o:?}") }
    }
    fn as_assignment(self) -> Self::Assignment {
        match self { AtlantisNode::Construct(AnyConstructNode::Lua(LuaNode::Assignment(n))) => n,
            o => panic!("expected Assignment, got {o:?}") }
    }
    fn as_conditional(self) -> Self::Conditional {
        match self { AtlantisNode::Construct(AnyConstructNode::Lua(LuaNode::Conditional(n))) => n,
            o => panic!("expected Conditional, got {o:?}") }
    }
    fn as_call(self) -> Self::Call {
        match self { AtlantisNode::Construct(AnyConstructNode::Lua(LuaNode::Call(n))) => n,
            o => panic!("expected Call, got {o:?}") }
    }
    fn as_container(self) -> LuaContainerNode {
        match self { AtlantisNode::Container(AnyContainerNode::Lua(c)) => c,
            o => panic!("expected LuaContainerNode, got {o:?}") }
    }
    fn is_unrecognised(self) -> bool { matches!(self, AtlantisNode::Unrecognised) }
}

// ── Cross-cutting: unrecognised / unsupported language ────────────────────

#[test]
fn unsupported_lua_kinds_produce_unrecognised() {
    for kind in ["return_statement", "comment", "string", "do_statement"] {
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
