use serde::Serialize;

use crate::model::node::{NodeRange, RawNode};
use crate::probe::treesitter::{NodeOutline, TsCapture, TsFieldNode};

/// Pointer to a navigation destination — enough to jump to and re-probe if needed.
#[derive(Debug, Serialize, Clone)]
pub struct NavigationTarget {
    pub node_type: String,
    pub range: NodeRange,
}

/// Pre-computed navigation targets for a resolved node.
#[derive(Debug, Serialize)]
pub struct NavigationInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_level: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prev_sibling: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_sibling: Option<NavigationTarget>,
    pub is_at_top: bool,
}

impl NavigationInfo {
    pub(super) fn resolve(
        all:           &[&NodeOutline],
        focus_idx:     usize,
        cap:           &TsCapture,
        is_recognised: impl Fn(RawNode) -> bool,
    ) -> Self {
        let parent = all.iter().skip(focus_idx + 1)
            .find(|n| is_recognised(RawNode::from(**n)))
            .map(|n| NavigationTarget::from(*n));

        let top_level = all.iter().rev()
            .find(|n| is_recognised(RawNode::from(**n)))
            .map(|n| NavigationTarget::from(*n));

        let supported_siblings: Vec<NavigationTarget> = cap.siblings.iter()
            .filter(|s| is_recognised(RawNode::from(*s)))
            .map(NavigationTarget::from)
            .collect();

        let (prev_sibling, next_sibling) = sibling_nav(&supported_siblings, &cap.node_type, &cap.range);

        let is_at_top = top_level.as_ref().is_some_and(|tl| {
            tl.range.start_row == cap.range.start_row &&
            tl.range.start_col == cap.range.start_col
        });

        Self { parent, top_level, prev_sibling, next_sibling, is_at_top }
    }
}

impl From<&NodeOutline> for NavigationTarget {
    fn from(n: &NodeOutline) -> Self {
        Self { node_type: n.node_type.clone(), range: n.range.clone() }
    }
}

impl From<&TsFieldNode> for NavigationTarget {
    fn from(f: &TsFieldNode) -> Self {
        Self { node_type: f.node_type.clone(), range: f.range.clone() }
    }
}

fn sibling_nav(
    siblings:   &[NavigationTarget],
    node_type:  &str,
    range:      &NodeRange,
) -> (Option<NavigationTarget>, Option<NavigationTarget>) {
    if siblings.len() <= 1 {
        return (None, None);
    }
    let pos = siblings.iter().position(|t| {
        t.node_type == node_type &&
        t.range.start_row == range.start_row &&
        t.range.start_col == range.start_col
    });
    match pos {
        Some(idx) => {
            let prev = (idx + siblings.len() - 1) % siblings.len();
            let next = (idx + 1) % siblings.len();
            (Some(siblings[prev].clone()), Some(siblings[next].clone()))
        }
        None => (None, None),
    }
}
