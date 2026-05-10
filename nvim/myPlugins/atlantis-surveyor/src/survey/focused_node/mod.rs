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
use self::container_skip::{ResolutionStep, SoleChildResolution};

pub use self::navigation::NavigationInfo;

mod container_skip;

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
    pub fn from_raw(
        raw:         &Dictionary,
        focus_mode:  FocusMode,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Self::from_ancestry(ancestry, focus_mode, target_hint)
    }

    #[must_use]
    pub fn from_ancestry(
        ancestry:    NodeAncestry,
        focus_mode:  FocusMode,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<Option<Self>, AtlantisError> {
        let lang = ancestry.language();
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        let focus_idx = match ancestry.find_focus_idx(focus_mode, target_hint) {
            Ok(idx) => idx,
            Err(_)  => return Ok(None),
        };

        let focus_node_outline = all[focus_idx];
        let parent_ref = all.get(focus_idx + 1).copied();

        let node_snapshot = treesitter::snapshot(
            focus_node_outline.range.start_row,
            focus_node_outline.range.start_col,
            Some(&focus_node_outline.node_type),
            Some((focus_node_outline.range.start_row, focus_node_outline.range.start_col)),
            Some((focus_node_outline.range.end_row,   focus_node_outline.range.end_col)),
        )?;

        let node       = lang.classify(RawNode::from(&node_snapshot), parent_ref);
        let navigation = NavigationInfo::from_snapshot(lang, &all, focus_idx, &node_snapshot);
        let node_type  = node_snapshot.node_type.clone();
        let range      = node_snapshot.range.clone();

        Ok(Some(match focus_mode {
            FocusMode::Container => {
                let outline = FocusedNode::<Container>::compute_outline(
                    &node_snapshot.children,
                    |raw| lang.classify(raw.into(), parent_ref),
                );
                let focused = FocusedNode {
                    node_type, range, node, navigation,
                    mode: Container { outline },
                };

                // Auto-drill: if the container has exactly one recognised child,
                // descend into it (iterating for nested transparent containers).
                let mut resolver = SoleChildResolution::new(focused, lang, &all, focus_idx, node_snapshot);
                loop {
                    match resolver.try_descend() {
                        ResolutionStep::Resolved(n) => return Ok(Some(n)),
                        ResolutionStep::Retain      => break,
                        ResolutionStep::Descend     => {
                            resolver.expand_binary_children();
                        }
                    }
                }
                resolver.expand_binary_children();
                resolver.into_container()
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
