use serde::Serialize;

use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode};
use crate::probe::language::Language;
use crate::probe::treesitter::{NodeOutline, NodeSnapshot};

use crate::model::NavigationTarget;

/// Pre-computed navigation targets for a resolved node.
#[derive(Debug, Serialize)]
pub struct NavigationInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_level: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nearest_body: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nearest_function: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prev_sibling: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_sibling: Option<NavigationTarget>,
    pub is_at_top: bool,
}

/// Classify a raw node and build a NavigationTarget. Returns None for Unrecognised nodes.
/// Shared by the sibling pipeline (NavigationInfo::resolve) and the container outline (outline.rs).
pub(in crate::survey::focused_node) fn as_navigation_target(
    raw:      RawNode,
    classify: &impl Fn(RawNode) -> AtlantisNode,
) -> Option<NavigationTarget> {
    let target_mode = match classify(raw.clone()) {
        AtlantisNode::Container(_) => FocusMode::Container,
        AtlantisNode::Construct(_) => FocusMode::Construct,
        AtlantisNode::Unrecognised => return None,
    };
    Some(NavigationTarget { node_type: raw.kind, range: raw.range, target_mode })
}

impl NavigationInfo {
    pub fn resolve(
        lang:          Language,
        all:           &[&NodeOutline],
        focus_idx:     usize,
        node_snapshot: &NodeSnapshot,
    ) -> Self {
        let focus_node = lang.classify(RawNode::from(all[focus_idx]), all.get(focus_idx + 1).copied());
        let current_mode = match focus_node {
            AtlantisNode::Container(_) => FocusMode::Container,
            _                          => FocusMode::Construct,
        };

        // Parent: nearest recognized ancestor that differs in construct kind from the focus.
        let parent = all.iter().enumerate().skip(focus_idx + 1)
            .find(|(i, _)| {
                let classified = lang.classify(RawNode::from(all[*i]), all.get(*i + 1).copied());
                !matches!(classified, AtlantisNode::Unrecognised)
                && !focus_node.same_construct_kind(&classified)
            })
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| lang.classify(raw, all.get(i + 1).copied())));

        let top_level = all.iter().enumerate().rev()
            .find(|(i, _)| !matches!(lang.classify(RawNode::from(all[*i]), all.get(*i + 1).copied()), AtlantisNode::Unrecognised))
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| lang.classify(raw, all.get(i + 1).copied())));

        let supported_siblings: Vec<NavigationTarget> = node_snapshot.siblings.iter()
            .filter_map(|s| as_navigation_target(RawNode::from(s), &|raw| lang.classify(raw, all.get(focus_idx + 1).copied())))
            .filter(|t| t.target_mode == current_mode)
            .collect();

        let (prev_sibling, next_sibling) = sibling_nav(&supported_siblings, &node_snapshot.node_type, &node_snapshot.range);

        let nearest_body = all.iter().enumerate().skip(focus_idx + 1)
            .find(|(_, n)| lang.is_body_container(&n.node_type))
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| lang.classify(raw, all.get(i + 1).copied())));

        let nearest_function = all.iter().enumerate().skip(focus_idx + 1)
            .find(|(_, n)| lang.is_function_construct(&n.node_type))
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| lang.classify(raw, all.get(i + 1).copied())));

        let is_at_top = top_level.as_ref().is_some_and(|tl| {
            tl.range.start_row == node_snapshot.range.start_row &&
            tl.range.start_col == node_snapshot.range.start_col
        });

        Self { parent, top_level, nearest_body, nearest_function, prev_sibling, next_sibling, is_at_top }
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
