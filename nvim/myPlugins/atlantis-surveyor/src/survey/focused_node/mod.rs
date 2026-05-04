mod actions;
pub(crate) mod ancestry;
mod navigation;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode};
use crate::probe::treesitter::{self, NodeOutline};

use self::ancestry::NodeAncestry;

pub use self::navigation::NavigationInfo;

/// A resolved node ready to be turned into a `SurveyResult` — holds classification,
/// position, and pre-computed navigation targets.
pub struct FocusedNode {
    pub node_type:  String,
    pub range:      NodeRange,
    pub node:       AtlantisNode,
    pub navigation: NavigationInfo,
}

impl FocusedNode {
    /// Parse the raw Lua ancestry dict and resolve the innermost supported node.
    /// Returns `None` for unknown or unsupported languages.
    pub fn from_raw(raw: &Dictionary, focus_mode: FocusMode) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Ok(Self::from_ancestry(ancestry, focus_mode))
    }

    pub fn from_ancestry(ancestry: NodeAncestry, focus_mode: FocusMode) -> Option<Self> {
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        // Find the innermost recognised node that matches the requested FocusMode.
        let first_idx = all.iter().position(|n| {
            let classified = ancestry.classify(RawNode::from(*n));
            match (focus_mode, classified) {
                (FocusMode::Construct, AtlantisNode::Construct(_)) => true,
                (FocusMode::Container, AtlantisNode::Container(_)) => true,
                _ => false,
            }
        })?;

        // Walk UP through consecutive ancestors that classify to the same construct kind
        // (e.g. assignment_statement → variable_declaration both resolve to Assignment).
        // Focusing the outermost means the user skips the intermediate wrapper entirely.
        let first_kind = ancestry.classify(RawNode::from(all[first_idx]));
        let focus_idx = all[first_idx..].iter()
            .enumerate()
            .take_while(|(_, n)| first_kind.same_construct_kind(&ancestry.classify(RawNode::from(**n))))
            .last()
            .map(|(i, _)| first_idx + i)
            .unwrap_or(first_idx);

        let outline = all[focus_idx];

        let node_snapshot = treesitter::snapshot(
            outline.range.start_row,
            outline.range.start_col,
            Some(&outline.node_type),
            Some((outline.range.start_row, outline.range.start_col)),
        ).ok()?;

        let node = ancestry.classify(RawNode::from(&node_snapshot));
        let navigation = NavigationInfo::resolve(&all, focus_idx, &node_snapshot, |raw| ancestry.classify(raw));

        Some(Self { node_type: node_snapshot.node_type, range: node_snapshot.range, node, navigation })
    }
}
