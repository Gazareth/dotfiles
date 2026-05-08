mod actions;
pub(crate) mod ancestry;
mod container_skip;
mod navigation;
mod outline;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode, OutlineItem};
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeOutline, NodeSnapshot, SnapshotChild};

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

impl FocusedNode<Construct> {
    fn from_snapshot(snapshot: NodeSnapshot, node: AtlantisNode, navigation: NavigationInfo) -> Self {
        FocusedNode {
            node_type: snapshot.node_type,
            range:     snapshot.range,
            node,
            navigation,
            mode: Construct,
        }
    }
}

impl FocusedNode<Container> {
    fn from_snapshot(
        lang:      Language,
        all:       &[&NodeOutline],
        focus_idx: usize,
        snapshot:  &NodeSnapshot,
        node:      AtlantisNode,
        navigation: NavigationInfo,
    ) -> Self {
        let outline = Self::compute_outline(
            &snapshot.children,
            |child: &SnapshotChild| lang.classify(RawNode::from(child), all.get(focus_idx).copied()),
        );
        FocusedNode {
            node_type: snapshot.node_type.clone(),
            range:     snapshot.range.clone(),
            node,
            navigation,
            mode: Container { outline },
        }
    }

    /// Consumes the container and, if it holds exactly one recognised child,
    /// returns the child's result directly. Delegates to `SoleChildResolution` for iteration.
    fn resolve_sole_child(self, lang: Language, all: &[&NodeOutline], focus_idx: usize, snapshot: NodeSnapshot) -> AnyFocusedNode {
        use self::container_skip::{SoleChildResolution, ResolutionStep};
        let mut resolution = SoleChildResolution::new(self, lang, all, focus_idx, snapshot);
        loop {
            match resolution.try_descend() {
                ResolutionStep::Resolved(result) => return result,
                ResolutionStep::Retain           => break,
                ResolutionStep::Descend          => {}
            }
        }
        resolution.expand_binary_children();
        resolution.into_container()
    }
}

// ── Runtime wrapper ───────────────────────────────────────────────────────

/// Returned by `from_ancestry` — the mode is a runtime decision so we need
/// a dynamic wrapper, analogous to `AtlantisNode::Construct` / `::Container`.
pub enum AnyFocusedNode {
    Construct(FocusedNode<Construct>),
    Container(FocusedNode<Container>),
}

impl From<FocusedNode<Construct>> for AnyFocusedNode {
    fn from(n: FocusedNode<Construct>) -> Self { AnyFocusedNode::Construct(n) }
}

impl AnyFocusedNode {
    pub fn node_type(&self) -> &str {
        match self {
            Self::Construct(n) => &n.node_type,
            Self::Container(n) => &n.node_type,
        }
    }

    #[must_use]
    pub fn from_raw(raw: &Dictionary, focus_mode: FocusMode, target_hint: Option<(&str, u32, u32)>) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Self::from_ancestry(ancestry, focus_mode, target_hint)
    }

    #[must_use]
    pub fn from_ancestry(ancestry: NodeAncestry, focus_mode: FocusMode, target_hint: Option<(&str, u32, u32)>) -> Result<Option<Self>, AtlantisError> {
        let lang      = ancestry.language();
        let all: Vec<&NodeOutline> = ancestry.all().collect();
        let focus_idx = ancestry.find_focus_idx(focus_mode, target_hint)?;

        let snapshot   = treesitter::snapshot(
            all[focus_idx].range.start_row,
            all[focus_idx].range.start_col,
            Some(&all[focus_idx].node_type),
            Some((all[focus_idx].range.start_row, all[focus_idx].range.start_col)),
            Some((all[focus_idx].range.end_row,   all[focus_idx].range.end_col)),
        )?;
        let node = {
            let raw = lang.classify(RawNode::from(&snapshot), all.get(focus_idx + 1).copied());
            // Promote to Leaf when the node is unrecognised but its parent is a Container —
            // this makes it a stable navigation endpoint rather than scanning up to the nearest construct.
            if matches!(raw, AtlantisNode::Unrecognised) {
                let parent_is_container = all.get(focus_idx + 1).map_or(false, |p| {
                    matches!(lang.classify(RawNode::from(*p), all.get(focus_idx + 2).copied()), AtlantisNode::Container(_))
                });
                if parent_is_container { AtlantisNode::Leaf } else { raw }
            } else {
                raw
            }
        };
        let nav  = NavigationInfo::from_snapshot(lang, &all, focus_idx, &snapshot);

        Ok(Some(match focus_mode {
            FocusMode::Construct => FocusedNode::<Construct>::from_snapshot(snapshot, node, nav).into(),
            FocusMode::Container => {
                let focused = FocusedNode::<Container>::from_snapshot(lang, &all, focus_idx, &snapshot, node, nav);
                focused.resolve_sole_child(lang, &all, focus_idx, snapshot)
            }
        }))
    }
}
