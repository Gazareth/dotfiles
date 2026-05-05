mod actions;
pub(crate) mod ancestry;
mod navigation;
mod outline;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode, OutlineItem};
use crate::probe::treesitter::{self, NodeOutline};

use self::ancestry::NodeAncestry;

pub use self::navigation::NavigationInfo;

// ── Mode typestates ───────────────────────────────────────────────────────

pub struct Construct;

pub struct Container {
    pub outline: Vec<OutlineItem>,
}

// ── FocusedNode<S> ───────────────────────────────────────────────────────

/// A resolved node ready to be turned into a `SurveyResult`.
/// The mode typestate `S` is either `Construct` or `Container`,
/// restricting `outline` to only exist on the container variant.
pub struct FocusedNode<S> {
    pub node_type:  String,
    pub range:      NodeRange,
    pub node:       AtlantisNode,
    pub navigation: NavigationInfo,
    pub mode:       S,
}

// ── Runtime wrapper ───────────────────────────────────────────────────────

/// Returned by `from_ancestry` — the mode is a runtime decision so we need
/// a dynamic wrapper, analogous to `AtlantisNode::Construct` / `::Container`.
pub enum AnyFocusedNode {
    Construct(FocusedNode<Construct>),
    Container(FocusedNode<Container>),
}

impl AnyFocusedNode {
    pub fn node_type(&self) -> &str {
        match self {
            Self::Construct(n) => &n.node_type,
            Self::Container(n) => &n.node_type,
        }
    }

    #[must_use]
    pub fn from_raw(raw: &Dictionary, focus_mode: FocusMode) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Self::from_ancestry(ancestry, focus_mode)
    }

    #[must_use]
    pub fn from_ancestry(ancestry: NodeAncestry, focus_mode: FocusMode) -> Result<Option<Self>, AtlantisError> {
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        // Find the innermost recognised node that matches the requested FocusMode.
        let first_idx = all.iter().position(|n| {
            let classified = ancestry.classify(RawNode::from(*n));
            match (focus_mode, classified) {
                (FocusMode::Construct, AtlantisNode::Construct(_)) => true,
                (FocusMode::Container, AtlantisNode::Container(_)) => true,
                _ => false,
            }
        }).ok_or(AtlantisError::UnsupportedLanguage)?;

        // Walk UP through consecutive ancestors that classify to the same construct kind
        // (e.g. assignment_statement → variable_declaration both resolve to Assignment).
        let first_kind = ancestry.classify(RawNode::from(all[first_idx]));
        let focus_idx = all[first_idx..].iter()
            .enumerate()
            .take_while(|(_, n)| first_kind.same_construct_kind(&ancestry.classify(RawNode::from(**n))))
            .last()
            .map(|(i, _)| first_idx + i)
            .unwrap_or(first_idx);

        let focus_node_outline = all[focus_idx];

        let node_snapshot = treesitter::snapshot(
            focus_node_outline.range.start_row,
            focus_node_outline.range.start_col,
            Some(&focus_node_outline.node_type),
            Some((focus_node_outline.range.start_row, focus_node_outline.range.start_col)),
        )?;

        let node       = ancestry.classify(RawNode::from(&node_snapshot));
        let navigation = NavigationInfo::resolve(&all, focus_idx, &node_snapshot, |raw| ancestry.classify(raw));
        let node_type  = node_snapshot.node_type.clone();
        let range      = node_snapshot.range.clone();

        Ok(Some(match focus_mode {
            FocusMode::Container => {
                let outline = FocusedNode::<Container>::compute_outline(
                    &node_snapshot.children,
                    |raw| ancestry.classify(raw),
                );
                AnyFocusedNode::Container(FocusedNode {
                    node_type, range, node, navigation,
                    mode: Container { outline },
                })
            }
            FocusMode::Construct => {
                AnyFocusedNode::Construct(FocusedNode {
                    node_type, range, node, navigation,
                    mode: Construct,
                })
            }
        }))
    }
}
