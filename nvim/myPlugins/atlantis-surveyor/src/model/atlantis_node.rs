use serde::Serialize;

use crate::model::lang::languages::{JavaScript, Lua, Python, TypeScript};
use crate::model::lang::{ResolveOutput, Resolve};
use crate::model::node::{Node, RawNode};
use crate::model::resolved::{AnyContainerNode, AnyConstructNode};
use crate::probe::language::Language;

/// Atlantis classification of a node — the resolved output of a `RawNode` against a language.
#[derive(Debug, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum AtlantisNode {
    /// A direct language construct — function, assignment, conditional, etc.
    Construct(AnyConstructNode),
    /// A structural grouping — parameter list, body, argument list, etc.
    Container(AnyContainerNode),
    /// Atlantis has no registered behaviour for this node type.
    Unrecognised,
}

impl AtlantisNode {
    pub fn from_raw(raw: RawNode, language: &Language) -> Self {
        match language {
            Language::Lua => resolve_output(
                Node::<Lua>::new(raw).resolve(),
                AnyConstructNode::Lua,
                AnyContainerNode::Lua,
            ),
            Language::JavaScript => resolve_output(
                Node::<JavaScript>::new(raw).resolve(),
                AnyConstructNode::JavaScript,
                AnyContainerNode::JavaScript,
            ),
            Language::TypeScript => resolve_output(
                Node::<TypeScript>::new(raw).resolve(),
                AnyConstructNode::TypeScript,
                AnyContainerNode::TypeScript,
            ),
            Language::Python => resolve_output(
                Node::<Python>::new(raw).resolve(),
                AnyConstructNode::Python,
                AnyContainerNode::Python,
            ),
            Language::Unknown => AtlantisNode::Unrecognised,
        }
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
