//! Test helpers — fluent builders for constructing and classifying Lua nodes.

use std::collections::HashMap;

use crate::model::node::{NodeRange, RawNode};
use crate::model::AtlantisNode;
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeSnapshot, SnapshotChild};

const ZERO: NodeRange = NodeRange { start_row: 0, start_col: 0, end_row: 0, end_col: 0 };

fn r(start_row: u32, start_col: u32, end_row: u32, end_col: u32) -> NodeRange {
    NodeRange { start_row, start_col, end_row, end_col }
}

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
    range:     NodeRange,
    fields:    Vec<(String, String, NodeRange)>,
    children:  Vec<(String, String, NodeRange)>,
}

impl SnapBuilder {
    pub fn field(mut self, name: &str, text: &str) -> Self {
        self.fields.push((name.to_owned(), text.to_owned(), ZERO));
        self
    }

    /// Like `field` but places the field at a specific source range.
    pub fn field_ranged(mut self, name: &str, text: &str, sr: u32, sc: u32, er: u32, ec: u32) -> Self {
        self.fields.push((name.to_owned(), text.to_owned(), r(sr, sc, er, ec)));
        self
    }

    pub fn child(mut self, kind: &str, text: &str) -> Self {
        self.children.push((kind.to_owned(), text.to_owned(), ZERO));
        self
    }

    /// Like `child` but places the child at a specific source range.
    pub fn child_ranged(mut self, kind: &str, text: &str, sr: u32, sc: u32, er: u32, ec: u32) -> Self {
        self.children.push((kind.to_owned(), text.to_owned(), r(sr, sc, er, ec)));
        self
    }

    fn to_snapshot(&self) -> NodeSnapshot {
        NodeSnapshot {
            node_type: self.node_type.clone(),
            text:      self.node_type.clone(),
            range:     self.range.clone(),
            fields: self.fields.iter().map(|(n, t, range)| {
                (n.clone(), SnapshotChild { node_type: n.clone(), text: t.clone(), range: range.clone() })
            }).collect(),
            children: self.children.iter().map(|(k, t, range)| {
                SnapshotChild { node_type: k.clone(), text: t.clone(), range: range.clone() }
            }).collect(),
            siblings: vec![],
        }
    }

    /// Pre-load this snapshot into the mock queue.
    pub fn inject(self) {
        treesitter::set_snapshot(self.to_snapshot());
    }

    /// Append this snapshot to the mock queue (for tests that need multiple snapshots).
    pub fn queue(self) {
        treesitter::push_snapshot(self.to_snapshot());
    }

    pub fn build(self) -> NodeSnapshot {
        self.to_snapshot()
    }
}

/// Start building a `NodeSnapshot`. Chain `.field()` / `.child()` then `.inject()`, `.queue()`, or `.build()`.
pub fn snap(node_type: &str) -> SnapBuilder {
    SnapBuilder { node_type: node_type.to_owned(), range: ZERO, fields: vec![], children: vec![] }
}
