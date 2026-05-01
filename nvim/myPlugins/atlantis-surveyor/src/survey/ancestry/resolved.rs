use crate::error::AtlantisError;
use crate::model::node::{NodeRange, RawNode};
use crate::probe::treesitter;

use super::node::AtlantisNode;
use super::super::{NavigationInfo, NavigationTarget};
use super::NodeAncestry;

/// Fully resolved node at a given ancestry index — classification and navigation computed together.
pub(in crate::survey) struct ResolvedNode {
    pub(in crate::survey) bufnr:      i32,
    pub(in crate::survey) node_type:  String,
    pub(in crate::survey) range:      NodeRange,
    pub(in crate::survey) node:       AtlantisNode,
    pub(in crate::survey) navigation: NavigationInfo,
}

impl ResolvedNode {
    pub(super) fn resolve(
        bufnr:     i32,
        idx:       usize,
        ancestry:  &NodeAncestry,
        top_level: Option<NavigationTarget>,
    ) -> Result<Self, AtlantisError> {
        let outline = ancestry.get(idx);
        let cap = treesitter::capture(
            bufnr,
            outline.range.start_row,
            outline.range.start_col,
            Some(&outline.node_type),
            Some((outline.range.start_row, outline.range.start_col)),
        )?;

        let node = ancestry.resolve_node(RawNode::from(&cap));

        let parent = ancestry.parent_of(idx);

        let supported_siblings: Vec<NavigationTarget> = cap.siblings.iter()
            .filter(|s| !matches!(
                ancestry.resolve_node(RawNode::from(*s)),
                AtlantisNode::Unrecognised
            ))
            .map(NavigationTarget::from)
            .collect();

        let (prev_sibling, next_sibling) = sibling_nav(&supported_siblings, &cap.node_type, &cap.range);

        let is_at_top = top_level.as_ref().map_or(false, |tl| {
            tl.range.start_row == cap.range.start_row && tl.range.start_col == cap.range.start_col
        });

        let navigation = NavigationInfo { parent, top_level, prev_sibling, next_sibling, is_at_top };

        Ok(ResolvedNode { bufnr, node_type: cap.node_type, range: cap.range, node, navigation })
    }
}

fn sibling_nav(
    siblings:  &[NavigationTarget],
    node_type: &str,
    range:     &NodeRange,
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
