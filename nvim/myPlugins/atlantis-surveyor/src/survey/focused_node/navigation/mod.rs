use serde::Serialize;

use crate::model::lang::NodeKind;
use crate::model::node::{NodeRange, RawNode};
use crate::model::AtlantisNode;
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeOutline, NodeSnapshot, SnapshotChild};
use crate::model::NavigationTarget;

pub(super) mod binary_navigation;

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

    /// Resolves prev/next sibling using the general walk-up / walk-down algorithm.
    fn resolve_siblings(
        ctx: &AncestryContext,
        node_snapshot: &NodeSnapshot,
        is_leaf_focus: bool,
    ) -> (Option<NavigationTarget>, Option<NavigationTarget>) {
        // When focused on a return_statement inside a function body, treat it as a
        // function-level component and cycle between [params, body, return] instead
        // of the body's statement-level siblings.
        if matches!(ctx.lang.node_kind_for(&node_snapshot.node_type), Some(NodeKind::ReturnStatement)) {
            let grandparent_is_fn = ctx.all.get(ctx.focus_idx + 2)
                .map_or(false, |gp| matches!(ctx.lang.node_kind_for(&gp.node_type), Some(NodeKind::Function)));
            if grandparent_is_fn {
                let siblings = Self::collect_function_components_for_return(ctx, node_snapshot);
                return sibling_nav(&siblings, &node_snapshot.node_type, &node_snapshot.range);
            }
        }

        Self::resolve_siblings_general(ctx, node_snapshot, is_leaf_focus)
    }

    /// Walk up to the nearest Recognised ancestor (semantic parent), snapshot it,
    /// then walk down each child branch — descending through transparent nodes —
    /// to collect the sibling set.
    fn resolve_siblings_general(
        ctx:           &AncestryContext,
        node_snapshot: &NodeSnapshot,
        is_leaf_focus: bool,
    ) -> (Option<NavigationTarget>, Option<NavigationTarget>) {
        // Find the nearest Recognised ancestor above the focus.
        let sp_idx = (ctx.focus_idx + 1..ctx.all.len()).find(|&i| {
            matches!(
                ctx.lang.classify(RawNode::from(ctx.all[i]), ctx.all.get(i + 1).copied()),
                AtlantisNode::Recognised(_)
            )
        });
        let Some(sp_idx) = sp_idx else { return (None, None); };
        let sp = ctx.all[sp_idx];

        let Ok(sp_snap) = treesitter::snapshot(
            sp.range.start_row, sp.range.start_col,
            Some(&sp.node_type),
            Some((sp.range.start_row, sp.range.start_col)),
            Some((sp.range.end_row,   sp.range.end_col)),
        ) else { return (None, None); };

        let mut siblings: Vec<NavigationTarget> = sp_snap.children.iter()
            .filter_map(|child| Self::resolve_child_sibling(ctx, child, sp, is_leaf_focus))
            .collect();

        // When the semantic parent is a Body inside a Function, the return statement is
        // promoted to function-level and excluded from the body's statement sibling set.
        let sp_parent = ctx.all.get(sp_idx + 1);
        if matches!(ctx.lang.node_kind_for(&sp.node_type), Some(NodeKind::Body))
            && matches!(sp_parent.and_then(|p| ctx.lang.node_kind_for(&p.node_type)), Some(NodeKind::Function))
        {
            siblings.retain(|t| !matches!(ctx.lang.node_kind_for(&t.node_type), Some(NodeKind::ReturnStatement)));
        }

        if is_leaf_focus {
            Self::inject_leaf_focus_if_absent(&mut siblings, node_snapshot);
        }
        Self::maybe_add_return_sibling(ctx.lang, &mut siblings, node_snapshot, ctx.parent_at(ctx.focus_idx));

        // maybe_add_return_sibling is guarded by parent_ref being a Function. When the focus
        // is a parameter whose immediate parent is a transparent ParameterList, parent_ref is
        // ParameterList — so the return is not added. Handle that gap here.
        let focus_parent_is_pl = matches!(
            ctx.parent_at(ctx.focus_idx).and_then(|p| ctx.lang.node_kind_for(&p.node_type)),
            Some(NodeKind::ParameterList)
        );
        if focus_parent_is_pl
            && matches!(ctx.lang.node_kind_for(&sp.node_type), Some(NodeKind::Function))
        {
            if let Some(body_nav) = siblings.iter()
                .find(|s| matches!(ctx.lang.node_kind_for(&s.node_type), Some(NodeKind::Body)))
                .cloned()
            {
                if let Ok(body_snap) = treesitter::snapshot(
                    body_nav.range.start_row, body_nav.range.start_col,
                    None,
                    Some((body_nav.range.start_row, body_nav.range.start_col)),
                    Some((body_nav.range.end_row,   body_nav.range.end_col)),
                ) {
                    if let Some(ret) = body_snap.children.into_iter().rev()
                        .find(|c| matches!(ctx.lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)))
                    {
                        if !siblings.iter().any(|t| {
                            t.range.start_row == ret.range.start_row
                                && t.range.start_col == ret.range.start_col
                        }) {
                            siblings.push(NavigationTarget {
                                node_type:      ret.node_type,
                                classification: "ReturnStatement".to_string(),
                                range:          ret.range,
                                key:            None,
                            });
                            siblings.sort_by(|a, b| {
                                a.range.start_row.cmp(&b.range.start_row)
                                    .then(a.range.start_col.cmp(&b.range.start_col))
                            });
                        }
                    }
                }
            }
        }

        sibling_nav(&siblings, &node_snapshot.node_type, &node_snapshot.range)
    }

    /// Resolves a single child of the semantic parent into a sibling NavigationTarget.
    ///
    /// - Children in the focused ancestry branch resolve as the focused node itself.
    /// - Translucent children are snapshotted to get their real child count:
    ///   if ≤1 and not a Body, descend recursively; otherwise include as opaque.
    /// - Body nodes are always included as opaque siblings (never descended into).
    /// - Non-translucent children are classified normally.
    fn resolve_child_sibling(
        ctx:           &AncestryContext,
        child:         &SnapshotChild,
        sp:            &NodeOutline,
        is_leaf_focus: bool,
    ) -> Option<NavigationTarget> {
        // If this child overlaps a node in the focused ancestry, use the focused
        // node as the sibling representative (avoids an extra snapshot and gives
        // the correct child_count from NodeOutline).
        let in_ancestry = ctx.all[..=ctx.focus_idx].iter().any(|n| {
            n.range.start_row == child.range.start_row
                && n.range.start_col == child.range.start_col
                && n.range.end_row   == child.range.end_row
                && n.range.end_col   == child.range.end_col
        });
        if in_ancestry {
            let focused = ctx.all[ctx.focus_idx];
            return as_navigation_target(
                RawNode::from(focused),
                &|r| ctx.lang.classify(r, ctx.all.get(ctx.focus_idx + 1).copied()),
            );
        }

        let is_translucent_kind = ctx.lang.node_kind_for(&child.node_type)
            .map_or(false, |k| k.is_translucent());

        if is_translucent_kind {
            // Body is a semantic container — always include it as an opaque sibling,
            // never descend into it.
            let is_body = matches!(ctx.lang.node_kind_for(&child.node_type), Some(NodeKind::Body));

            let Ok(snap) = treesitter::snapshot(
                child.range.start_row, child.range.start_col,
                Some(&child.node_type),
                Some((child.range.start_row, child.range.start_col)),
                Some((child.range.end_row,   child.range.end_col)),
            ) else { return None; };

            let actual_count = snap.children.len();

            if actual_count <= 1 && !is_body {
                return snap.children.first().and_then(|inner| {
                    // If the inner child is the focused node, return it classified against
                    // its real parent (the translucent list), not sp.
                    let in_focused = ctx.all[..=ctx.focus_idx].iter().any(|n| {
                        n.range.start_row == inner.range.start_row
                            && n.range.start_col == inner.range.start_col
                            && n.range.end_row   == inner.range.end_row
                            && n.range.end_col   == inner.range.end_col
                    });
                    if in_focused {
                        let focused = ctx.all[ctx.focus_idx];
                        return as_navigation_target(
                            RawNode::from(focused),
                            &|r| ctx.lang.classify(r, ctx.all.get(ctx.focus_idx + 1).copied()),
                        );
                    }
                    // Classify inner against the translucent parent (e.g. ParameterList) so that
                    // language reclassification (identifier → Parameter) applies correctly.
                    let pl_outline = NodeOutline {
                        node_type:   child.node_type.clone(),
                        range:       child.range.clone(),
                        child_count: actual_count,
                    };
                    as_navigation_target(
                        RawNode::from(inner),
                        &|r| ctx.lang.classify(r, Some(&pl_outline)),
                    )
                });
            }

            // Opaque: force child_count ≥ 2 so Guard B does not fire.
            let mut raw = RawNode::from(child);
            raw.child_count = actual_count.max(2);
            return as_navigation_target(raw, &|r| ctx.lang.classify(r, Some(sp)));
        }

        // Non-translucent: classify normally, with is_leaf_focus promotion for
        // unrecognised siblings when the focus itself is a Leaf.
        let raw = RawNode::from(child);
        let classified = {
            let c = ctx.lang.classify(raw.clone(), Some(sp));
            if is_leaf_focus && matches!(c, AtlantisNode::Unrecognised) {
                AtlantisNode::Leaf
            } else {
                c
            }
        };
        if matches!(classified, AtlantisNode::Unrecognised) {
            return None;
        }
        as_navigation_target(raw, &|r| ctx.lang.classify(r, Some(sp)))
    }

    /// When focused on a return_statement inside a function body, build siblings from
    /// the function's named children (params + body) plus the return itself.
    fn collect_function_components_for_return(
        ctx:           &AncestryContext,
        node_snapshot: &NodeSnapshot,
    ) -> Vec<NavigationTarget> {
        let block = match ctx.all.get(ctx.focus_idx + 1) {
            Some(b) => *b,
            None    => return vec![],
        };

        let Ok(block_snap) = treesitter::snapshot(
            block.range.start_row, block.range.start_col,
            Some(&block.node_type),
            Some((block.range.start_row, block.range.start_col)),
            Some((block.range.end_row,   block.range.end_col)),
        ) else { return vec![]; };

        let parent_of_block = ctx.all.get(ctx.focus_idx + 2).copied();

        let mut siblings: Vec<NavigationTarget> = block_snap.siblings.iter()
            .filter_map(|s| {
                let kind = ctx.lang.node_kind_for(&s.node_type)?;
                if !matches!(kind, NodeKind::ParameterList | NodeKind::Body) {
                    return None;
                }
                let mut raw = RawNode::from(s);
                raw.child_count = raw.child_count.max(2);
                as_navigation_target(raw, &|r| ctx.lang.classify(r, parent_of_block))
            })
            .collect();

        // Redirect any transparent ParameterList component to the inner parameter.
        for sibling in siblings.iter_mut() {
            if matches!(ctx.lang.node_kind_for(&sibling.node_type), Some(NodeKind::ParameterList)) {
                Self::redirect_transparent_param_nav_target(ctx.lang, sibling);
            }
        }

        siblings.push(NavigationTarget {
            node_type:      node_snapshot.node_type.clone(),
            classification: "ReturnStatement".to_string(),
            range:          node_snapshot.range.clone(),
            key:            None,
        });

        siblings.sort_by(|a, b| {
            a.range.start_row.cmp(&b.range.start_row)
                .then(a.range.start_col.cmp(&b.range.start_col))
        });

        siblings
    }

    /// Redirects a ParameterList NavigationTarget to its single inner child when the list
    /// is transparent (exactly 1 child). No-op if the snapshot fails or has ≠ 1 child.
    fn redirect_transparent_param_nav_target(_lang: Language, target: &mut NavigationTarget) {
        let Ok(snap) = treesitter::snapshot(
            target.range.start_row, target.range.start_col,
            Some(&target.node_type),
            Some((target.range.start_row, target.range.start_col)),
            Some((target.range.end_row,   target.range.end_col)),
        ) else { return };

        if snap.children.len() != 1 { return; }

        let inner = &snap.children[0];
        target.node_type      = inner.node_type.clone();
        target.range          = inner.range.clone();
        target.classification = "Parameter".to_string();
    }

    fn maybe_add_return_sibling(
        lang:               Language,
        supported_siblings: &mut Vec<NavigationTarget>,
        node_snapshot:      &NodeSnapshot,
        parent_ref:         Option<&NodeOutline>,
    ) {
        if !matches!(parent_ref.and_then(|p| lang.node_kind_for(&p.node_type)), Some(NodeKind::Function)) {
            return;
        }

        let ret: Option<SnapshotChild> = match lang.node_kind_for(&node_snapshot.node_type) {
            Some(NodeKind::Body) => {
                node_snapshot.children.iter()
                    .rev()
                    .find(|c| matches!(lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)))
                    .cloned()
            }
            Some(NodeKind::ParameterList) => {
                // Body is already in the built sibling set; snapshot it to find the return.
                let body_sib = supported_siblings.iter()
                    .find(|s| matches!(lang.node_kind_for(&s.node_type), Some(NodeKind::Body)));
                body_sib.and_then(|body| {
                    treesitter::snapshot(
                        body.range.start_row, body.range.start_col,
                        None,
                        Some((body.range.start_row, body.range.start_col)),
                        Some((body.range.end_row,   body.range.end_col)),
                    ).ok()
                }).and_then(|body_snap| {
                    body_snap.children.into_iter()
                        .rev()
                        .find(|c| matches!(lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)))
                })
            }
            _ => return,
        };

        let Some(ret) = ret else { return };

        if supported_siblings.iter().any(|t| {
            t.range.start_row == ret.range.start_row && t.range.start_col == ret.range.start_col
        }) {
            return;
        }

        supported_siblings.push(NavigationTarget {
            node_type:      ret.node_type,
            classification: "ReturnStatement".to_string(),
            range:          ret.range,
            key:            None,
        });
        supported_siblings.sort_by(|a, b| {
            a.range.start_row.cmp(&b.range.start_row)
                .then(a.range.start_col.cmp(&b.range.start_col))
        });
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
