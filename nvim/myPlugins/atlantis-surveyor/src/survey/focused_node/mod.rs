mod actions;
mod ancestry;
mod navigation;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::node::{NodeRange, RawNode};
use crate::model::AtlantisNode;
use crate::probe::treesitter::{self, NodeOutline};

use self::ancestry::NodeAncestry;

pub use self::navigation::NavigationInfo;

/// A resolved node ready to be turned into a `SurveyResult` — holds classification,
/// position, and pre-computed navigation targets.
pub(super) struct FocusedNode {
    pub node_type:  String,
    pub range:      NodeRange,
    pub node:       AtlantisNode,
    pub navigation: NavigationInfo,
}

impl FocusedNode {
    /// Parse the raw Lua ancestry dict and resolve the innermost supported node.
    /// Returns `None` for unknown or unsupported languages.
    pub(super) fn from_raw(raw: &Dictionary) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Ok(Self::from_ancestry(ancestry))
    }

    fn from_ancestry(ancestry: NodeAncestry) -> Option<Self> {
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        let is_recognised = |raw: RawNode| {
            !matches!(ancestry.classify(raw), AtlantisNode::Unrecognised)
        };

        let focus_idx = all.iter().position(|n| is_recognised(RawNode::from(*n)))?;

        let outline = all[focus_idx];

        let node_snapshot = treesitter::snapshot(
            outline.range.start_row,
            outline.range.start_col,
            Some(&outline.node_type),
            Some((outline.range.start_row, outline.range.start_col)),
        ).ok()?;

        let node = ancestry.classify(RawNode::from(&node_snapshot));
        let navigation = NavigationInfo::resolve(&all, focus_idx, &node_snapshot, is_recognised);

        Some(Self { node_type: node_snapshot.node_type, range: node_snapshot.range, node, navigation })
    }
}
