use crate::model::node::{NodeRange, RawNode};
use crate::model::AtlantisNode;
use crate::probe::treesitter::{self, NodeOutline};

use super::ancestry::NodeAncestry;
use super::navigation_targets::NavigationInfo;

/// A resolved node ready to be turned into a `SurveyResult` — holds classification,
/// position, and pre-computed navigation targets.
pub(super) struct FocusedNode {
    pub node_type:  String,
    pub range:      NodeRange,
    pub node:       AtlantisNode,
    pub navigation: NavigationInfo,
}

impl FocusedNode {
    /// Get all the info for the focused node from the raw ancestry.
    /// - resolve the innermost supported node from an ancestry tree.
    /// - Return `None` for unknown or unsupported languages.
    pub(super) fn from_ancestry(ancestry: NodeAncestry) -> Option<Self> {
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        let is_recognised = |raw: RawNode| {
            !matches!(ancestry.classify(raw), AtlantisNode::Unrecognised)
        };

        let focus_idx = all.iter().position(|n| is_recognised(RawNode::from(*n)))?;

        let outline = all[focus_idx];

        let cap = treesitter::capture(
            outline.range.start_row,
            outline.range.start_col,
            Some(&outline.node_type),
            Some((outline.range.start_row, outline.range.start_col)),
        ).ok()?;

        let node = ancestry.classify(RawNode::from(&cap));
        let navigation = NavigationInfo::resolve(&all, focus_idx, &cap, is_recognised);

        Some(Self { node_type: cap.node_type, range: cap.range, node, navigation })
    }
}
