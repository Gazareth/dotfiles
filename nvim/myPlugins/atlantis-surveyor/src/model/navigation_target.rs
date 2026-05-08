use serde::{Deserialize, Serialize};
use crate::model::node::{NodeRange, RawNode};
use crate::model::FocusMode;

/// A labelled navigation destination for container outline display.
#[derive(Debug, Serialize, Clone)]
pub struct OutlineItem {
    pub label:       String,
    pub node_type:   String,
    pub range:       NodeRange,
    pub target_mode: FocusMode,
}

/// Pointer to a navigation destination — enough to jump to and re-probe if needed.
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct NavigationTarget {
    pub node_type: String,
    pub range: NodeRange,
    pub target_mode: FocusMode,
}

impl NavigationTarget {
    pub fn from_raw(raw: &RawNode, target_mode: FocusMode) -> Self {
        Self {
            node_type: raw.kind.clone(),
            range: raw.range.clone(),
            target_mode,
        }
    }

    pub fn container(raw: &RawNode) -> Self {
        Self::from_raw(raw, FocusMode::Container)
    }

    pub fn construct(raw: &RawNode) -> Self {
        Self::from_raw(raw, FocusMode::Construct)
    }
}
