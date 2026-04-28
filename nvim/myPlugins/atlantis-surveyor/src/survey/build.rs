use std::collections::HashMap;

use crate::model::lang::languages::{JavaScript, Lua, Python, TypeScript};
use crate::model::lang::{ResolveOutput, Resolve};
use crate::model::node::{Node, RawNode};
use crate::model::resolved::{AnyContainerNode, AnyStandardNode};
use crate::probe::language::{detect, SnapshotLanguage};
use crate::probe::treesitter::{self, TsSnapshot};
use crate::survey::{AtlantisNode, AtlantisVariant};

pub fn build(bufnr: i32, row: u32, col: u32) -> AtlantisNode {
    match treesitter::capture(bufnr, row, col) {
        Ok(snap) => {
            let raw = snapshot_to_raw_node(&snap);
            let variant = resolve_for_language(&snap.filetype, raw);
            AtlantisNode::ok(bufnr, snap.node_type, snap.range, snap.text, variant)
        }
        Err(e) => AtlantisNode::err(bufnr, e),
    }
}

fn snapshot_to_raw_node(snap: &TsSnapshot) -> RawNode {
    RawNode {
        kind: snap.node_type.clone(),
        text: snap.text.clone(),
        range: snap.range.clone(),
        fields: snap
            .fields
            .iter()
            .map(|(k, f)| {
                (k.clone(), RawNode {
                    kind: f.node_type.clone(),
                    text: f.text.clone(),
                    range: f.range.clone(),
                    fields: HashMap::new(),
                    children: vec![],
                })
            })
            .collect(),
        children: snap
            .children
            .iter()
            .map(|c| RawNode {
                kind: c.node_type.clone(),
                text: c.text.clone(),
                range: c.range.clone(),
                fields: HashMap::new(),
                children: vec![],
            })
            .collect(),
    }
}

fn resolve_for_language(filetype: &str, raw: RawNode) -> AtlantisVariant {
    match detect(filetype) {
        SnapshotLanguage::Lua => resolve_output(
            Node::<Lua>::new(raw).resolve(),
            AnyStandardNode::Lua,
            AnyContainerNode::Lua,
        ),
        SnapshotLanguage::JavaScript => resolve_output(
            Node::<JavaScript>::new(raw).resolve(),
            AnyStandardNode::JavaScript,
            AnyContainerNode::JavaScript,
        ),
        SnapshotLanguage::TypeScript => resolve_output(
            Node::<TypeScript>::new(raw).resolve(),
            AnyStandardNode::TypeScript,
            AnyContainerNode::TypeScript,
        ),
        SnapshotLanguage::Python => resolve_output(
            Node::<Python>::new(raw).resolve(),
            AnyStandardNode::Python,
            AnyContainerNode::Python,
        ),
        SnapshotLanguage::Unknown => AtlantisVariant::Unrecognised,
    }
}

fn resolve_output<S, C>(
    output: ResolveOutput<S, C>,
    wrap_std: impl FnOnce(S) -> AnyStandardNode,
    wrap_ctr: impl FnOnce(C) -> AnyContainerNode,
) -> AtlantisVariant {
    match output {
        ResolveOutput::Standard(n)  => AtlantisVariant::Standard(wrap_std(n)),
        ResolveOutput::Container(c) => AtlantisVariant::Container(wrap_ctr(c)),
        ResolveOutput::Unresolved   => AtlantisVariant::Unrecognised,
    }
}
