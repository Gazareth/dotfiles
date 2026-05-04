//! Test helpers — fluent builders for constructing and classifying Lua nodes.

use std::collections::HashMap;

use crate::model::node::{NodeRange, RawNode};
use crate::model::AtlantisNode;
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeSnapshot, SnapshotChild};

const ZERO: NodeRange = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 0 };

fn leaf(kind: &str, text: &str) -> RawNode {
    RawNode { kind: kind.into(), text: text.into(), range: ZERO,
              fields: HashMap::new(), children: vec![] }
}

// ── Node builder ──────────────────────────────────────────────────────────

pub struct NodeBuilder {
    kind:     String,
    language: Language,
    fields:   Vec<(String, String)>,
    children: Vec<(String, String)>,
}

impl NodeBuilder {
    pub fn field(mut self, name: &str, value: &str) -> Self {
        self.fields.push((name.to_owned(), value.to_owned()));
        self
    }

    pub fn child(mut self, kind: &str, text: &str) -> Self {
        self.children.push((kind.to_owned(), text.to_owned()));
        self
    }

    pub fn classify(self) -> AtlantisNode {
        let raw = RawNode {
            kind:     self.kind.clone(),
            text:     self.kind,
            range:    ZERO,
            fields:   self.fields.iter().map(|(n, t)| (n.clone(), leaf(n, t))).collect(),
            children: self.children.iter().map(|(k, t)| leaf(k, t)).collect(),
        };
        AtlantisNode::from_raw(raw, &self.language)
    }
}

/// Start building a Lua node.  Chain `.field()` / `.child()` then `.classify()`.
pub fn lua(kind: &str) -> NodeBuilder {
    NodeBuilder { kind: kind.to_owned(), language: Language::Lua,
                  fields: vec![], children: vec![] }
}

/// Start building a node in an unsupported language.
pub fn unknown(kind: &str) -> NodeBuilder {
    NodeBuilder { kind: kind.to_owned(), language: Language::Unknown,
                  fields: vec![], children: vec![] }
}

// ── Snapshot builder ──────────────────────────────────────────────────────

pub struct SnapBuilder {
    node_type: String,
    fields:    Vec<(String, String)>,
    children:  Vec<(String, String)>,
}

impl SnapBuilder {
    pub fn field(mut self, name: &str, text: &str) -> Self {
        self.fields.push((name.to_owned(), text.to_owned()));
        self
    }

    pub fn child(mut self, kind: &str, text: &str) -> Self {
        self.children.push((kind.to_owned(), text.to_owned()));
        self
    }

    fn to_snapshot(&self) -> NodeSnapshot {
        NodeSnapshot {
            node_type: self.node_type.clone(),
            text:      self.node_type.clone(),
            range:     ZERO,
            fields: self.fields.iter().map(|(n, t)| {
                (n.clone(), SnapshotChild { node_type: n.clone(), text: t.clone(), range: ZERO })
            }).collect(),
            children: self.children.iter().map(|(k, t)| {
                SnapshotChild { node_type: k.clone(), text: t.clone(), range: ZERO }
            }).collect(),
            siblings: vec![],
        }
    }

    /// Pre-load this snapshot into the mock.
    pub fn inject(self) {
        treesitter::set_snapshot(self.to_snapshot());
    }

    pub fn build(self) -> NodeSnapshot {
        self.to_snapshot()
    }
}

/// Start building a `NodeSnapshot`.  Chain `.field()` / `.child()` then `.inject()` or `.build()`.
pub fn snap(node_type: &str) -> SnapBuilder {
    SnapBuilder { node_type: node_type.to_owned(), fields: vec![], children: vec![] }
}
