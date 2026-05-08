use serde::Serialize;

use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, FocusMode, OutlineItem};
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeOutline, NodeSnapshot};

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
        AtlantisNode::Construct(_) | AtlantisNode::Leaf => FocusMode::Construct,
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

        // A Leaf focus is an unrecognised node whose immediate ancestor is a Container.
        let is_leaf_focus = matches!(focus_node, AtlantisNode::Unrecognised)
            && all.get(focus_idx + 1).map_or(false, |p| {
                matches!(lang.classify(RawNode::from(*p), all.get(focus_idx + 2).copied()), AtlantisNode::Container(_))
            });

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

        // Sibling navigation: when inside a binary_expression chain, snapshot the outermost
        // binary_expression and flatten all nested ones into a single list of operands.
        // This gives correct prev/next across the whole expression regardless of tree nesting.
        // Otherwise fall back to direct siblings with mode filtering.
        let outermost_binary: Option<(usize, &&NodeOutline)> =
            all.iter().enumerate().skip(focus_idx + 1)
                .find(|(i, n)| {
                    n.node_type == "binary_expression"
                    && !all.get(i + 1).map_or(false, |p| p.node_type == "binary_expression")
                });

        let (prev_sibling, next_sibling) = if let Some((_, bn)) = outermost_binary {
            let flat = gather_binary_siblings(lang, bn);
            sibling_nav(&flat, &node_snapshot.node_type, &node_snapshot.range)
        } else {
            // Non-binary context: use direct siblings from the snapshot with mode filter.
            // For Leaf focus (unrecognised child of a Container), promote unrecognised siblings
            // to Leaf and inject the focus node when absent (anonymous nodes aren't in the
            // tree-sitter named sibling list, so sibling_nav would never locate the current position).
            let parent_ref = all.get(focus_idx + 1).copied();
            let mut supported_siblings: Vec<NavigationTarget> = node_snapshot.siblings.iter()
                .filter_map(|s| {
                    let classify = |raw: RawNode| {
                        let c = lang.classify(raw, parent_ref);
                        if is_leaf_focus && matches!(c, AtlantisNode::Unrecognised) { AtlantisNode::Leaf } else { c }
                    };
                    as_navigation_target(RawNode::from(s), &classify)
                })
                .filter(|t| is_leaf_focus || t.target_mode == current_mode)
                .collect();

            if is_leaf_focus {
                let already_present = supported_siblings.iter().any(|t| {
                    t.range.start_row == node_snapshot.range.start_row
                    && t.range.start_col == node_snapshot.range.start_col
                });
                if !already_present {
                    supported_siblings.push(NavigationTarget {
                        node_type:   node_snapshot.node_type.clone(),
                        range:       node_snapshot.range.clone(),
                        target_mode: FocusMode::Construct,
                    });
                    supported_siblings.sort_by(|a, b| {
                        a.range.start_row.cmp(&b.range.start_row)
                            .then(a.range.start_col.cmp(&b.range.start_col))
                    });
                }
            }

            sibling_nav(&supported_siblings, &node_snapshot.node_type, &node_snapshot.range)
        };

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

/// Snapshots the outermost binary_expression and recursively flattens all nested
/// binary_expression Containers, returning a flat list of operand NavigationTargets.
fn gather_binary_siblings(lang: Language, root: &NodeOutline) -> Vec<NavigationTarget> {
    let Ok(snap) = treesitter::snapshot(
        root.range.start_row,
        root.range.start_col,
        Some("binary_expression"),
        Some((root.range.start_row, root.range.start_col)),
        Some((root.range.end_row,   root.range.end_col)),
    ) else { return vec![]; };

    let root_ref = NodeOutline { node_type: "binary_expression".into(), range: root.range.clone() };
    let mut outline = super::FocusedNode::<super::Container>::compute_outline(
        &snap.children,
        |c| lang.classify(RawNode::from(c), Some(&root_ref)),
    );

    flatten_binary_outline(lang, &mut outline);

    outline.into_iter()
        .map(|item| NavigationTarget { node_type: item.node_type, range: item.range, target_mode: item.target_mode })
        .collect()
}

/// Recursively expands binary_expression Container entries in an outline until only
/// non-binary operands remain.
fn flatten_binary_outline(lang: Language, outline: &mut Vec<OutlineItem>) {
    loop {
        let Some(idx) = outline.iter().position(|item| {
            item.node_type == "binary_expression" && item.target_mode == FocusMode::Container
        }) else { break; };

        let item = outline.remove(idx);
        let child_ref = NodeOutline { node_type: item.node_type.clone(), range: item.range.clone() };
        let Ok(snap) = treesitter::snapshot(
            item.range.start_row, item.range.start_col,
            Some("binary_expression"),
            Some((item.range.start_row, item.range.start_col)),
            Some((item.range.end_row,   item.range.end_col)),
        ) else { break; };

        let children = super::FocusedNode::<super::Container>::compute_outline(
            &snap.children,
            |c| lang.classify(RawNode::from(c), Some(&child_ref)),
        );
        outline.extend(children);
        outline.sort_by(|a, b| {
            a.range.start_row.cmp(&b.range.start_row)
                .then(a.range.start_col.cmp(&b.range.start_col))
        });
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
