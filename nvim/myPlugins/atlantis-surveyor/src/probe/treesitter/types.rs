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
    pub node_type:   String,
    pub range:       NodeRange,
    /// Named child count as reported by Tree-sitter. Used to distinguish a sole
    /// variable in an assignment (`local x = 1`) from multiple variables
    /// (`local x, y = …`), which changes whether the cursor stops here or climbs.
    pub child_count: usize,
}

impl NodeOutline {
    /// Construct with `child_count = 0` (the common case for nodes that do not
    /// use the child-count to influence classification).
    #[cfg(test)]
    pub fn new(node_type: impl Into<String>, range: NodeRange) -> Self {
        Self { node_type: node_type.into(), range, child_count: 0 }
    }
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
            kind:        snapshot.node_type.clone(),
            text:        snapshot.text.clone(),
            range:       snapshot.range.clone(),
            fields:      snapshot.fields.iter()
                            .map(|(k, f)| (k.clone(), RawNode::from(f)))
                            .collect(),
            children:    snapshot.children.iter().map(RawNode::from).collect(),
            child_count: snapshot.children.len(),
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
            child_count: 0,
        }
    }
}



impl From<&NodeOutline> for RawNode {
    fn from(n: &NodeOutline) -> Self {
        RawNode {
            kind:        n.node_type.clone(),
            text:        String::new(),
            range:       n.range.clone(),
            fields:      HashMap::new(),
            children:    vec![],
            child_count: n.child_count,
        }
    }
}
