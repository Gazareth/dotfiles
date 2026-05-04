//! Shared Tree-sitter node types used by both the real probe and the test mock.

use std::collections::HashMap;
use crate::model::node::{NodeRange, RawNode};

/// A single child node within a snapshot (field, unnamed child, or sibling).
#[derive(Debug, Clone)]
pub struct SnapshotChild {
    pub node_type: String,
    pub range:     NodeRange,
    pub text:      String,
}

/// Sparse position-only ancestry entry from Lua — just enough to identify and locate a node.
#[derive(Debug, Clone)]
pub struct NodeOutline {
    pub node_type: String,
    pub range:     NodeRange,
}

/// Full Tree-sitter node snapshot — rich with fields, children, siblings, and text.
#[derive(Debug, Clone)]
pub struct NodeSnapshot {
    pub node_type: String,
    pub range:     NodeRange,
    pub text:      String,
    pub fields:    HashMap<String, SnapshotChild>,
    /// Unnamed named children — positional nodes like parameters, arguments.
    pub children:  Vec<SnapshotChild>,
    /// All named siblings (for filtering supported navigation in the model).
    pub siblings:  Vec<SnapshotChild>,
}

// ── From impls — shared by both mod.rs and mock.rs ───────────────────────

impl From<&NodeSnapshot> for RawNode {
    fn from(snapshot: &NodeSnapshot) -> Self {
        RawNode {
            kind:     snapshot.node_type.clone(),
            text:     snapshot.text.clone(),
            range:    snapshot.range.clone(),
            fields:   snapshot.fields.iter()
                        .map(|(k, f)| (k.clone(), RawNode::from(f)))
                        .collect(),
            children: snapshot.children.iter().map(RawNode::from).collect(),
        }
    }
}

impl From<&SnapshotChild> for RawNode {
    fn from(f: &SnapshotChild) -> Self {
        RawNode {
            kind:     f.node_type.clone(),
            text:     f.text.clone(),
            range:    f.range.clone(),
            fields:   HashMap::new(),
            children: vec![],
        }
    }
}

impl From<&NodeOutline> for RawNode {
    fn from(n: &NodeOutline) -> Self {
        RawNode {
            kind:     n.node_type.clone(),
            text:     String::new(),
            range:    n.range.clone(),
            fields:   HashMap::new(),
            children: vec![],
        }
    }
}
