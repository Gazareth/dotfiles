use serde::Serialize;

use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode};
use crate::probe::treesitter::{NodeOutline, NodeSnapshot, SnapshotChild};

use crate::model::NavigationTarget;

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
    pub fn resolve(
        all:           &[&NodeOutline],
        focus_idx:     usize,
        node_snapshot: &NodeSnapshot,
        classify:      impl Fn(RawNode) -> AtlantisNode,
    ) -> Self {
        let focus_node = classify(RawNode::from(all[focus_idx]));
        let current_mode = match focus_node {
            AtlantisNode::Container(_) => FocusMode::Container,
            _                          => FocusMode::Construct,
        };

        let to_target = |n: RawNode| {
            let classified = classify(n.clone());
            let target_mode = match classified {
                AtlantisNode::Container(_) => FocusMode::Container,
                _                          => FocusMode::Construct,
            };
            NavigationTarget {
                node_type: n.kind,
                range: n.range,
                target_mode,
            }
        };

        // Parent: nearest recognized ancestor that is:
        //   • not the same construct class as the focus (avoids jumping between e.g. Assignment wrappers)
        //   • (we no longer skip containers!)
        let parent = all.iter().skip(focus_idx + 1)
            .find(|n| {
                let classified = classify(RawNode::from(**n));
                !matches!(classified, AtlantisNode::Unrecognised)
                && !focus_node.same_construct_kind(&classified)
            })
            .map(|n| to_target(RawNode::from(*n)));

        let top_level = all.iter().rev()
            .find(|n| !matches!(classify(RawNode::from(**n)), AtlantisNode::Unrecognised))
            .map(|n| to_target(RawNode::from(*n)));

        let supported_siblings: Vec<NavigationTarget> = node_snapshot.siblings.iter()
            .filter(|s| {
                let classified = classify(RawNode::from(*s));
                match (current_mode, classified) {
                    (FocusMode::Construct, AtlantisNode::Construct(_)) => true,
                    (FocusMode::Container, AtlantisNode::Container(_)) => true,
                    _ => false,
                }
            })
            .map(|s| to_target(RawNode::from(s)))
            .collect();

        let (prev_sibling, next_sibling) = sibling_nav(&supported_siblings, &node_snapshot.node_type, &node_snapshot.range);

        let is_at_top = top_level.as_ref().is_some_and(|tl| {
            tl.range.start_row == node_snapshot.range.start_row &&
            tl.range.start_col == node_snapshot.range.start_col
        });

        Self { parent, top_level, prev_sibling, next_sibling, is_at_top }
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
