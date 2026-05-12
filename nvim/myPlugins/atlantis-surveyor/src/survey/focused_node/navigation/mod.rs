use serde::Serialize;

use crate::model::node::{NodeRange, RawNode};
use crate::model::AtlantisNode;
use crate::probe::language::Language;
use crate::probe::treesitter::NodeOutline;
use crate::probe::treesitter::NodeSnapshot;
use crate::model::NavigationTarget;

pub(super) mod binary_navigation;
use binary_navigation::gather_binary_siblings;

/// Context bundling ancestry state to reduce parameter threading and redundant classifications.
struct AncestryContext<'a> {
    lang: Language,
    all: &'a [&'a NodeOutline],
    focus_idx: usize,
    /// Pre-resolved classification of the immediate parent (at focus_idx + 1).
    parent_classification: Option<AtlantisNode>,
}

impl<'a> AncestryContext<'a> {
    fn new(lang: Language, all: &'a [&'a NodeOutline], focus_idx: usize) -> Self {
        let parent_idx = focus_idx + 1;
        let parent_classification = all.get(parent_idx).map(|p| {
            lang.classify(RawNode::from(*p), all.get(parent_idx + 1).copied())
        });

        Self { lang, all, focus_idx, parent_classification }
    }
    /// Gets the parent node (immediate ancestor) at the given index.
    fn parent_at(&self, idx: usize) -> Option<&'a NodeOutline> {
        self.all.get(idx + 1).copied()
    }
}

/// Pre-computed navigation targets for a resolved node.
#[derive(Debug, Serialize)]
pub struct NavigationInfo {
    /// The immediate semantic parent. This is the nearest ancestor that represents
    /// a different node kind than the focus.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<NavigationTarget>,

    /// The topmost recognized node in the file.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_level: Option<NavigationTarget>,

    /// The nearest ancestor that acts as a body container (e.g., a statement block).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nearest_body: Option<NavigationTarget>,

    /// The nearest ancestor that represents a function construct.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub nearest_function: Option<NavigationTarget>,

    /// The previous sibling within the current focus's semantic group.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prev_sibling: Option<NavigationTarget>,

    /// The next sibling within the current focus's semantic group.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_sibling: Option<NavigationTarget>,

    /// True if the focus is already at the top-level node.
    pub is_at_top: bool,
}

/// Classify a raw node and build a NavigationTarget. Returns None for Unrecognised nodes.
/// Shared by the sibling pipeline (NavigationInfo::from_snapshot) and the outline builder (outline.rs).
pub(in crate::survey::focused_node) fn as_navigation_target(
    raw:      RawNode,
    classify: &impl Fn(RawNode) -> AtlantisNode,
) -> Option<NavigationTarget> {
    let classified = classify(raw.clone());
    if matches!(classified, AtlantisNode::Unrecognised) {
        return None;
    }

    Some(NavigationTarget {
        node_type: raw.kind,
        classification: classified.classification_name(),
        range: raw.range,
        key: None,
    })
}

/// Checks if a NavigationTarget matches the given node type and range position.
fn position_matches(target: &NavigationTarget, node_type: &str, range: &NodeRange) -> bool {
    target.node_type == node_type
        && target.range.start_row == range.start_row
        && target.range.start_col == range.start_col
}

impl NavigationInfo {
    pub fn from_snapshot(
        lang:          Language,
        all:           &[&NodeOutline],
        focus_idx:     usize,
        node_snapshot: &NodeSnapshot,
    ) -> Self {
        let ctx = AncestryContext::new(lang, all, focus_idx);
        
        let focus_node = ctx.lang.classify(RawNode::from(all[focus_idx]), ctx.parent_at(focus_idx));
        let is_leaf_focus = matches!(focus_node, AtlantisNode::Leaf);

        let top_level = Self::resolve_top_level(&ctx);
        let (prev_sibling, next_sibling) = Self::resolve_siblings(&ctx, node_snapshot, is_leaf_focus);
        let is_at_top = Self::is_at_top(&top_level, node_snapshot);

        Self {
            parent:           Self::resolve_parent(&ctx, &focus_node),
            top_level,
            nearest_body:     Self::resolve_nearest(&ctx, Language::is_body_container),
            nearest_function: Self::resolve_nearest(&ctx, Language::is_function_construct),
            prev_sibling,
            next_sibling,
            is_at_top,
        }
    }

    /// Finds the nearest ancestor that differs in construct kind from the focus.
    fn resolve_parent(ctx: &AncestryContext, focus_node: &AtlantisNode) -> Option<NavigationTarget> {
        let focus_range = &ctx.all[ctx.focus_idx].range;

        ctx.all.iter().enumerate().skip(ctx.focus_idx + 1)
            .find(|(i, n)| {
                let classified = if *i == ctx.focus_idx + 1 {
                    ctx.parent_classification.clone()
                } else {
                    Some(ctx.lang.classify(RawNode::from(ctx.all[*i]), ctx.parent_at(*i)))
                };

                classified.is_some_and(|c| {
                    if matches!(c, AtlantisNode::Unrecognised) { return false; }
                    if focus_node.same_construct_kind(&c) { return false; }

                    // Skip grouping wrappers that don't expand the range
                    if n.range == *focus_range {
                        return false;
                    }

                    true
                })
            })
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| ctx.lang.classify(raw, ctx.parent_at(i))))
    }

    /// Finds the topmost recognised ancestor.
    fn resolve_top_level(ctx: &AncestryContext) -> Option<NavigationTarget> {
        ctx.all.iter().enumerate().rev()
            .find(|(i, _)| !matches!(ctx.lang.classify(RawNode::from(ctx.all[*i]), ctx.parent_at(*i)), AtlantisNode::Unrecognised))
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| ctx.lang.classify(raw, ctx.parent_at(i))))
    }

    /// Resolves prev/next sibling, with special handling for binary expression chains.
    fn resolve_siblings(
        ctx: &AncestryContext,
        node_snapshot: &NodeSnapshot,
        is_leaf_focus: bool,
    ) -> (Option<NavigationTarget>, Option<NavigationTarget>) {
        if let Some((_, bn)) = Self::find_outermost_binary(ctx) {
            let flat = gather_binary_siblings(ctx.lang, bn);
            sibling_nav(&flat, &node_snapshot.node_type, &node_snapshot.range)
        } else {
            Self::resolve_direct_siblings(ctx, node_snapshot, is_leaf_focus)
        }
    }

    /// Locates the outermost binary_expression ancestor (for flattening operand chains).
    fn find_outermost_binary<'a>(ctx: &AncestryContext<'a>) -> Option<(usize, &'a NodeOutline)> {
        ctx.all.iter().enumerate().skip(ctx.focus_idx + 1)
            .find(|(i, n)| {
                n.node_type == "binary_expression"
                && !ctx.all.get(i + 1).map_or(false, |p| p.node_type == "binary_expression")
            })
            .map(|(i, n)| (i, *n))
    }

    /// Resolves siblings from the snapshot, with mode filtering and leaf focus injection.
    fn resolve_direct_siblings(
        ctx: &AncestryContext,
        node_snapshot: &NodeSnapshot,
        is_leaf_focus: bool,
    ) -> (Option<NavigationTarget>, Option<NavigationTarget>) {
        let supported_siblings = Self::build_supported_siblings(ctx, node_snapshot, is_leaf_focus);
        sibling_nav(&supported_siblings, &node_snapshot.node_type, &node_snapshot.range)
    }

    /// Builds the list of supported siblings, filtered by kind and with optional Leaf focus injection.
    fn build_supported_siblings(
        ctx: &AncestryContext,
        node_snapshot: &NodeSnapshot,
        is_leaf_focus: bool,
    ) -> Vec<NavigationTarget> {
        let parent_ref = ctx.parent_at(ctx.focus_idx);
        let mut supported_siblings: Vec<NavigationTarget> = node_snapshot.siblings.iter()
            .filter_map(|s| {
                let classify = |raw: RawNode| {
                    let c = ctx.lang.classify(raw, parent_ref);
                    if is_leaf_focus && matches!(c, AtlantisNode::Unrecognised) { AtlantisNode::Leaf } else { c }
                };
                as_navigation_target(RawNode::from(s), &classify)
            })
            .collect();

        if is_leaf_focus {
            Self::inject_leaf_focus_if_absent(&mut supported_siblings, node_snapshot);
        }

        supported_siblings
    }

    /// Adds the focus node to the sibling list if it's absent (for Leaf focuses).
    fn inject_leaf_focus_if_absent(supported_siblings: &mut Vec<NavigationTarget>, node_snapshot: &NodeSnapshot) {
        let already_present = supported_siblings.iter().any(|t| {
            position_matches(t, &node_snapshot.node_type, &node_snapshot.range)
        });
        if !already_present {
            supported_siblings.push(NavigationTarget {
                node_type:      node_snapshot.node_type.clone(),
                classification: String::new(),
                range:          node_snapshot.range.clone(),
                key:            None,
            });
            supported_siblings.sort_by(|a, b| {
                a.range.start_row.cmp(&b.range.start_row)
                    .then(a.range.start_col.cmp(&b.range.start_col))
            });
        }
    }

    /// Finds the nearest ancestor matching a predicate.
    fn resolve_nearest(
        ctx:       &AncestryContext,
        predicate: impl Fn(&Language, &str) -> bool,
    ) -> Option<NavigationTarget> {
        ctx.all.iter().enumerate().skip(ctx.focus_idx + 1)
            .find(|(_, n)| predicate(&ctx.lang, &n.node_type))
            .and_then(|(i, n)| as_navigation_target(RawNode::from(*n), &|raw| ctx.lang.classify(raw, ctx.parent_at(i))))
    }

    /// Checks if the focus is at the top level.
    fn is_at_top(top_level: &Option<NavigationTarget>, node_snapshot: &NodeSnapshot) -> bool {
        top_level.as_ref().is_some_and(|tl| {
            position_matches(tl, &node_snapshot.node_type, &node_snapshot.range)
        })
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
    let pos = siblings.iter().position(|t| position_matches(t, node_type, range));
    match pos {
        Some(idx) => {
            let prev = (idx + siblings.len() - 1) % siblings.len();
            let next = (idx + 1) % siblings.len();
            (Some(siblings[prev].clone()), Some(siblings[next].clone()))
        }
        None => (None, None),
    }
}
