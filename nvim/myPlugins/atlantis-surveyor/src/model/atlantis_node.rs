use serde::Serialize;

use crate::model::lang::languages::{JavaScript, Lua, Python, TypeScript};
use crate::model::lang::{ResolveOutput, Resolve};
use crate::model::node::{Node, RawNode};
use crate::model::resolved::{AnyContainerNode, AnyConstructNode};
use crate::probe::language::Language;

/// Atlantis classification of a node — the resolved output of a `RawNode` against a language.
#[derive(Debug, Serialize, Clone)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum AtlantisNode {
    /// A direct language construct — function, assignment, conditional, etc.
    Construct(AnyConstructNode),
    /// A structural grouping — parameter list, body, argument list, etc.
    Container(AnyContainerNode),
    /// A recognised navigation endpoint that is a direct child of a recognised Container
    /// but has no further Atlantis structure (e.g. `nil`, `identifier` inside an expression list).
    Leaf,
    /// Atlantis has no registered behaviour for this node type.
    Unrecognised,
}

impl AtlantisNode {
    pub fn from_raw(raw: RawNode, language: &Language) -> Self {
        match language {
            Language::Lua        => resolve_output(Node::<Lua>::new(raw).resolve(),        AnyConstructNode::Lua,        AnyContainerNode::Lua),
            Language::JavaScript => resolve_output(Node::<JavaScript>::new(raw).resolve(), AnyConstructNode::JavaScript, AnyContainerNode::JavaScript),
            Language::TypeScript => resolve_output(Node::<TypeScript>::new(raw).resolve(), AnyConstructNode::TypeScript, AnyContainerNode::TypeScript),
            Language::Python     => resolve_output(Node::<Python>::new(raw).resolve(),     AnyConstructNode::Python,     AnyContainerNode::Python),
            Language::Unknown    => AtlantisNode::Unrecognised,
        }
    }

    /// Returns `true` when both nodes are constructs of the **same variant** in the same
    /// language — e.g. two `LuaNode::Assignment` nodes, regardless of their inner state.
    ///
    /// Used by navigation to detect semantically-identical wrappers in the ancestry chain
    /// (e.g. `assignment_statement` inside `variable_declaration`) so they can be collapsed.
    pub fn same_construct_kind(&self, other: &Self) -> bool {
        use AnyConstructNode::*;
        match (self, other) {
            (Self::Construct(Lua(a)),        Self::Construct(Lua(b)))        => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Construct(JavaScript(a)), Self::Construct(JavaScript(b))) => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Construct(TypeScript(a)), Self::Construct(TypeScript(b))) => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Construct(Python(a)),     Self::Construct(Python(b)))     => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Container(AnyContainerNode::Lua(a)),        Self::Container(AnyContainerNode::Lua(b)))        => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Container(AnyContainerNode::JavaScript(a)), Self::Container(AnyContainerNode::JavaScript(b))) => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Container(AnyContainerNode::TypeScript(a)), Self::Container(AnyContainerNode::TypeScript(b))) => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Container(AnyContainerNode::Python(a)),     Self::Container(AnyContainerNode::Python(b)))     => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Leaf, Self::Leaf) => true,
            _ => false,
        }
    }

    /// Returns the `FocusMode` for this node classification.
    pub fn focus_mode(&self) -> crate::model::FocusMode {
        use crate::model::FocusMode;
        match self {
            AtlantisNode::Container(_) => FocusMode::Container,
            AtlantisNode::Construct(_) | AtlantisNode::Leaf => FocusMode::Construct,
            AtlantisNode::Unrecognised => FocusMode::Construct,
        }
    }

    /// Returns the human-readable classification name for this node.
    pub fn classification_name(&self) -> String {
        match self {
            AtlantisNode::Construct(c) => c.node_type_name(),
            AtlantisNode::Container(c) => c.node_type_name(),
            AtlantisNode::Leaf         => "Leaf",
            AtlantisNode::Unrecognised => "Unrecognised",
        }.to_string()
    }
}

fn resolve_output<S, C>(
    output:   ResolveOutput<S, C>,
    wrap_std: impl FnOnce(S) -> AnyConstructNode,
    wrap_ctr: impl FnOnce(C) -> AnyContainerNode,
) -> AtlantisNode {
    match output {
        ResolveOutput::Construct(n) => AtlantisNode::Construct(wrap_std(n)),
        ResolveOutput::Container(c) => AtlantisNode::Container(wrap_ctr(c)),
        ResolveOutput::Unresolved   => AtlantisNode::Unrecognised,
    }
}
