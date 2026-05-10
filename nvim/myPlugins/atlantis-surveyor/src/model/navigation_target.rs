use serde::{Deserialize, Serialize};
use crate::model::node::{NodeRange, RawNode};

/// A labelled navigation destination for container outline display.
#[derive(Debug, Serialize, Clone)]
pub struct OutlineItem {
    pub label:       String,
    pub node_type:   String,
    pub range:       NodeRange,
}

/// Pointer to a navigation destination — enough to jump to and re-probe if needed.
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct NavigationTarget {
    pub node_type: String,
    pub classification: String,
    pub range: NodeRange,
}

impl NavigationTarget {
    pub fn from_raw(raw: &RawNode) -> Self {
        Self {
            node_type: raw.kind.clone(),
            classification: String::new(),
            range: raw.range.clone(),
        }
    }
}
