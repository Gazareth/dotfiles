use serde::{Deserialize, Serialize};
use crate::model::node::{NodeRange, RawNode};

/// A labelled navigation destination for outline display.
#[derive(Debug, Serialize, Clone)]
pub struct OutlineItem {
    pub label:     String,
    pub node_type: String,
    pub range:     NodeRange,
    /// Pinned hotkey hint, stamped by the owning node's state at extraction time.
    /// When present, the UI should prefer this key over the generic sequential assignment.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hint_key:  Option<&'static str>,
}

/// Pointer to a navigation destination — enough to jump to and re-probe if needed.
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct NavigationTarget {
    pub node_type: String,
    pub classification: String,
    pub range: NodeRange,
    /// Pinned hotkey hint. Not serialized — used only to propagate to OutlineItem.
    #[serde(skip)]
    pub key: Option<&'static str>,
}

impl NavigationTarget {
    pub fn from_raw(raw: &RawNode) -> Self {
        Self {
            node_type: raw.kind.clone(),
            classification: String::new(),
            range: raw.range.clone(),
            key: None,
        }
    }

    /// Constructs a NavigationTarget with a pinned hotkey hint.
    pub fn with_key(raw: &RawNode, key: &'static str) -> Self {
        Self {
            node_type: raw.kind.clone(),
            classification: String::new(),
            range: raw.range.clone(),
            key: Some(key),
        }
    }
}
