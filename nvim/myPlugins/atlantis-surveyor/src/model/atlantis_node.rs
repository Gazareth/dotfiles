use serde::Serialize;

use crate::model::lang::languages::{JavaScript, Lua, Python, TypeScript};
use crate::model::lang::Resolve;
use crate::model::node::{Node, RawNode};
use crate::model::resolved::AnyNode;
use crate::probe::language::Language;

/// Atlantis classification of a node — the resolved output of a `RawNode` against a language.
#[allow(clippy::large_enum_variant)] // `AnyNode` holds fully-decoded node data inline (strings, ranges, navigation targets) — the size comes from its content, not an oversight
#[derive(Debug, Serialize, Clone)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum AtlantisNode {
    /// A node recognised by Atlantis as having structure or behaviour.
    Recognised(AnyNode),
    /// A terminal node within a transparent structural grouping (e.g. `nil`,
    /// `identifier` inside an expression list) that has no further Atlantis structure.
    Leaf,
    /// Atlantis has no registered behaviour for this node type.
    Unrecognised,
}

impl AtlantisNode {
    pub fn from_raw(raw: RawNode, language: &Language) -> Self {
        match language {
            Language::Lua        => Self::wrap(AnyNode::Lua(Node::<Lua>::new(raw).resolve())),
            Language::JavaScript => Self::wrap(AnyNode::JavaScript(Node::<JavaScript>::new(raw).resolve())),
            Language::TypeScript => Self::wrap(AnyNode::TypeScript(Node::<TypeScript>::new(raw).resolve())),
            Language::Python     => Self::wrap(AnyNode::Python(Node::<Python>::new(raw).resolve())),
            Language::Unknown    => AtlantisNode::Unrecognised,
        }
    }

    fn wrap(node: AnyNode) -> Self {
        if node.node_type_name() == "Unresolved" {
            AtlantisNode::Unrecognised
        } else {
            AtlantisNode::Recognised(node)
        }
    }

    /// Returns `true` when both nodes are constructs of the **same variant** in the same
    /// language — e.g. two `LuaNode::Assignment` nodes, regardless of their inner state.
    ///
    /// Used by navigation to detect semantically-identical wrappers in the ancestry chain
    /// (e.g. `assignment_statement` inside `variable_declaration`) so they can be collapsed.
    pub fn same_construct_kind(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Recognised(AnyNode::Lua(a)),        Self::Recognised(AnyNode::Lua(b)))        => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Recognised(AnyNode::JavaScript(a)), Self::Recognised(AnyNode::JavaScript(b))) => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Recognised(AnyNode::TypeScript(a)), Self::Recognised(AnyNode::TypeScript(b))) => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Recognised(AnyNode::Python(a)),     Self::Recognised(AnyNode::Python(b)))     => std::mem::discriminant(a) == std::mem::discriminant(b),
            (Self::Leaf, Self::Leaf) => true,
            _ => false,
        }
    }

    /// Returns (range, hint_key) pairs from the node's keyed NavigationTarget fields.
    /// Used to stamp matching OutlineItems with their preferred UI hotkey.
    pub fn keyed_outline_hints(&self) -> Vec<(crate::model::node::NodeRange, &'static str)> {
        match self {
            AtlantisNode::Recognised(n) => n.keyed_outline_hints(),
            _ => vec![],
        }
    }



    /// Returns the ranges of any children that should be suppressed from the outline.
    pub fn outline_exceptions(&self) -> Vec<crate::model::node::NodeRange> {
        match self {
            AtlantisNode::Recognised(n) => n.outline_exceptions(),
            _ => vec![],
        }
    }



    /// Returns the human-readable classification name for this node.
    pub fn classification_name(&self) -> String {
        match self {
            AtlantisNode::Recognised(n) => n.node_type_name(),
            AtlantisNode::Leaf         => "Leaf",
            AtlantisNode::Unrecognised => "Unrecognised",
        }.to_string()
    }
}
