use std::cmp::Ordering;

use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode};
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeOutline, NodeSnapshot, SnapshotChild};

use super::{AnyFocusedNode, Container, Construct, FocusedNode};
use super::navigation::NavigationInfo;

pub(super) enum ResolutionStep {
    /// A concrete result was found — return it immediately.
    Resolved(AnyFocusedNode),
    /// The sole child was unrecognised or unreachable — keep the current container.
    Retain,
    /// Descended into a sole child container — loop again.
    Descend,
}

/// Resolves a `FocusedNode<Container>` to its sole recognised child when the
/// container holds exactly one entry. Iterates for nested transparent containers.
/// Retains the deepest successfully-resolved container as the fallback.
pub(super) struct SoleChildResolution<'a> {
    lang:         Language,
    all:          &'a [&'a NodeOutline],
    focus_idx:    usize,
    cur_snapshot: NodeSnapshot,
    cur_outline:  Vec<super::OutlineItem>,
    ancestors:    Vec<NodeOutline>,
    best_type:    String,
    best_range:   NodeRange,
    best_node:    AtlantisNode,
    best_nav:     NavigationInfo,
}

impl<'a> SoleChildResolution<'a> {
    /// Initialises resolution from the given container, taking ownership of its
    /// outline and field values as the starting `best_*` fallback state.
    pub(super) fn new(
        focused:   FocusedNode<Container>,
        lang:      Language,
        all:       &'a [&'a NodeOutline],
        focus_idx: usize,
        snapshot:  NodeSnapshot,
    ) -> Self {
        let ancestors = all[focus_idx..].iter()
            .map(|n| NodeOutline { node_type: n.node_type.clone(), range: n.range.clone() })
            .collect();
        let cur_outline = focused.mode.outline;
        SoleChildResolution {
            lang, all, focus_idx,
            cur_snapshot: snapshot,
            cur_outline,
            ancestors,
            best_type:  focused.node_type,
            best_range: focused.range,
            best_node:  focused.node,
            best_nav:   focused.navigation,
        }
    }

    /// Attempts to descend one level into the container's sole recognised child.
    pub(super) fn try_descend(&mut self) -> ResolutionStep {
        if self.cur_outline.len() != 1 { return ResolutionStep::Retain; }

        let Some((child_type, child_range, child_text)) = self.find_sole_child()
        else { return ResolutionStep::Retain; };

        let child_node_outline = NodeOutline { node_type: child_type.clone(), range: child_range.clone() };
        let parent_outline = self.ancestors.first().cloned();
        let parent = parent_outline.as_ref();
        let child_classified = self.lang.classify(RawNode::from(&child_node_outline), parent);
        self.ancestors.insert(0, child_node_outline);

        // Skips transparent containers from the NavigationInfo ancestry so that
        // "to parent" from the resolved child points to the grandparent, not back
        // to the transparent container (which would cause an infinite loop).
        let nav_refs: Vec<&NodeOutline> = std::iter::once(&self.ancestors[0])
            .chain(self.all[self.focus_idx + 1..].iter().copied())
            .collect();

        match child_classified {
            AtlantisNode::Unrecognised | AtlantisNode::Leaf => ResolutionStep::Retain,
            AtlantisNode::Construct(_) => {
                let Ok(child_snap) = treesitter::snapshot(
                    child_range.start_row, child_range.start_col,
                    Some(&child_type),
                    Some((child_range.start_row, child_range.start_col)),
                    Some((child_range.end_row,   child_range.end_col)),
                ) else { return ResolutionStep::Retain; };

                let child_classified = self.lang.classify(RawNode::from(&child_snap), parent);
                let nav = NavigationInfo::from_snapshot(self.lang, &nav_refs, 0, &child_snap);

                ResolutionStep::Resolved(AnyFocusedNode::Construct(FocusedNode {
                    node_type:  child_type,
                    range:      child_range,
                    node:       child_classified,
                    navigation: nav,
                    mode:       Construct,
                }))
            }
            AtlantisNode::Container(_) => {
                let Ok(child_snap) = treesitter::snapshot(
                    child_range.start_row, child_range.start_col,
                    Some(&child_type),
                    Some((child_range.start_row, child_range.start_col)),
                    Some((child_range.end_row,   child_range.end_col)),
                ) else { return ResolutionStep::Retain; };

                let child_container_ref = self.ancestors.first().unwrap();
                let child_outline = FocusedNode::<Container>::compute_outline(
                    &child_snap.children,
                    |gc: &SnapshotChild| self.lang.classify(RawNode::from(gc), Some(child_container_ref)),
                );
                let child_nav = NavigationInfo::from_snapshot(self.lang, &nav_refs, 0, &child_snap);

                self.best_type  = child_type;
                self.best_range = child_range;
                self.best_node  = child_classified;
                self.best_nav   = child_nav;
                self.cur_outline  = child_outline;
                self.cur_snapshot = child_snap;
                ResolutionStep::Descend
            }
        }
    }

    /// Converts the current best state into a `Container` result.
    /// Called when no further descent is possible or warranted.
    pub(super) fn into_container(self) -> AnyFocusedNode {
        AnyFocusedNode::Container(FocusedNode {
            node_type:  self.best_type,
            range:      self.best_range,
            node:       self.best_node,
            navigation: self.best_nav,
            mode: Container { outline: self.cur_outline },
        })
    }

    /// After the drill loop settles, recursively expands all `binary_expression` Container
    /// outline items until none remain, producing a flat list of operand nodes.
    /// Costs one extra snapshot per nesting level; stops when a snapshot fails.
    pub(super) fn expand_binary_children(&mut self) {
        loop {
            let Some(idx) = self.cur_outline.iter()
                .position(|item| item.node_type == "binary_expression" && item.target_mode == FocusMode::Container)
            else { break; };

            let item = self.cur_outline.remove(idx);
            let child_ref = NodeOutline { node_type: item.node_type.clone(), range: item.range.clone() };
            let Ok(child_snap) = treesitter::snapshot(
                item.range.start_row, item.range.start_col,
                Some("binary_expression"),
                Some((item.range.start_row, item.range.start_col)),
                Some((item.range.end_row,   item.range.end_col)),
            ) else { break; };

            let child_items = super::FocusedNode::<super::Container>::compute_outline(
                &child_snap.children,
                |gc| self.lang.classify(RawNode::from(gc), Some(&child_ref)),
            );

            self.cur_outline.extend(child_items);
            self.cur_outline.sort_by(|a, b| {
                match a.range.start_row.cmp(&b.range.start_row) {
                    Ordering::Equal => a.range.start_col.cmp(&b.range.start_col),
                    other => other,
                }
            });
        }
    }

    /// Finds the snapshot child whose position matches the single outline entry,
    /// returning its type, range, and text. Returns `None` if no match is found.
    fn find_sole_child(&self) -> Option<(String, NodeRange, String)> {
        let target = &self.cur_outline[0].range;
        self.cur_snapshot.children.iter()
            .find(|c| c.range.start_row == target.start_row && c.range.start_col == target.start_col)
            .map(|c| (c.node_type.clone(), c.range.clone(), c.text.clone()))
    }
}
