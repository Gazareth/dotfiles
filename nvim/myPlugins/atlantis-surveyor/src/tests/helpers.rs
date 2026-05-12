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
              fields: HashMap::new(), children: vec![], child_count: 0 }
}

// ── Node builder ──────────────────────────────────────────────────────────

pub struct NodeBuilder {
    kind:     String,
    language: Language,
    fields:   Vec<(String, String)>,
    children: Vec<(String, String)>,
}

impl NodeBuilder {
    pub fn field_text(mut self, name: &str, value: &str) -> Self {
        self.fields.push((name.to_owned(), value.to_owned()));
        self
    }

    pub fn child(mut self, kind: &str, text: &str) -> Self {
        self.children.push((kind.to_owned(), text.to_owned()));
        self
    }

    pub fn child_field(mut self, name: &str, child: NodeSnapshot) -> Self {
        self.fields.push((name.to_owned(), child.text.clone()));
        self.children.push((child.node_type.clone(), child.text));
        self
    }

    pub fn classify(self) -> AtlantisNode {
        let raw = RawNode {
            kind:        self.kind.clone(),
            text:        self.kind,
            range:       ZERO,
            fields:      self.fields.iter().map(|(n, t)| (n.clone(), leaf(n, t))).collect(),
            children:    self.children.iter().map(|(k, t)| leaf(k, t)).collect(),
            child_count: 0,
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
    text:      String,
    range:     NodeRange,
    fields:    HashMap<String, SnapshotChild>,
    children:  Vec<SnapshotChild>,
    siblings:  Vec<SnapshotChild>,
}

impl SnapBuilder {
    pub fn text(mut self, text: &str) -> Self {
        self.text = text.to_owned();
        self
    }

    pub fn range(mut self, sr: u32, sc: u32, er: u32, ec: u32) -> Self {
        self.range = r(sr, sc, er, ec);
        self
    }

    pub fn field_text(mut self, name: &str, text: &str) -> Self {
        self.fields.insert(name.to_owned(), SnapshotChild {
            node_type: name.to_owned(), text: text.to_owned(), range: ZERO,
        });
        self
    }

    pub fn field_ranged(mut self, name: &str, text: &str, sr: u32, sc: u32, er: u32, ec: u32) -> Self {
        self.fields.insert(name.to_owned(), SnapshotChild {
            node_type: name.to_owned(), text: text.to_owned(), range: r(sr, sc, er, ec),
        });
        self
    }

    pub fn child(mut self, child: impl IntoSnapshotChild) -> Self {
        self.children.push(child.into_snapshot_child());
        self
    }

    pub fn child_ranged(mut self, kind: &str, text: &str, sr: u32, sc: u32, er: u32, ec: u32) -> Self {
        self.children.push(SnapshotChild {
            node_type: kind.to_owned(), text: text.to_owned(), range: r(sr, sc, er, ec),
        });
        self
    }

    pub fn sibling_ranged(mut self, kind: &str, sr: u32, sc: u32, er: u32, ec: u32) -> Self {
        self.siblings.push(SnapshotChild {
            node_type: kind.to_owned(), text: String::new(), range: r(sr, sc, er, ec),
        });
        self
    }

    fn to_snapshot(&self) -> NodeSnapshot {
        NodeSnapshot {
            node_type: self.node_type.clone(),
            text:      self.text.clone(),
            range:     self.range.clone(),
            fields:    self.fields.clone(),
            children:  self.children.clone(),
            siblings:  self.siblings.clone(),
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
    SnapBuilder {
        node_type: node_type.to_owned(),
        text: node_type.to_owned(),
        range: ZERO,
        fields: HashMap::new(),
        children: vec![],
        siblings: vec![],
    }
}

pub trait IntoSnapshotChild {
    fn into_snapshot_child(self) -> SnapshotChild;
}

impl IntoSnapshotChild for (&str, &str) {
    fn into_snapshot_child(self) -> SnapshotChild {
        SnapshotChild {
            node_type: self.0.to_owned(),
            text: self.1.to_owned(),
            range: ZERO,
        }
    }
}

impl IntoSnapshotChild for SnapBuilder {
    fn into_snapshot_child(self) -> SnapshotChild {
        let s = self.to_snapshot();
        SnapshotChild {
            node_type: s.node_type,
            text: s.text,
            range: s.range,
        }
    }
}
