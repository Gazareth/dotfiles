mod actions;
pub(crate) mod ancestry;
mod navigation;
mod outline;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::lang::NodeKind;
use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, OutlineItem};
use crate::probe::treesitter::{self, NodeOutline};

use self::ancestry::NodeAncestry;

pub use self::navigation::NavigationInfo;


// ── FocusedNode ───────────────────────────────────────────────────────

/// A resolved node ready to be turned into a `SurveyResult`.
pub struct FocusedNode {
    pub node_type:  String,
    pub range:      NodeRange,
    pub node:       AtlantisNode,
    pub navigation: NavigationInfo,
    pub outline:    Vec<OutlineItem>,
}

impl FocusedNode {
    #[must_use]
    pub fn from_raw(
        raw:         &Dictionary,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Self::from_ancestry(ancestry, target_hint)
    }

    #[must_use]
    pub fn from_ancestry(
        ancestry:    NodeAncestry,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<Option<Self>, AtlantisError> {
        let lang = ancestry.language();
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        let focus_idx = match ancestry.find_focus_idx(target_hint) {
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
        let mut range  = node_snapshot.range.clone();

        // When the focus is a Body, trim its range to exclude any trailing return statement.
        // This makes the highlighted range and title reflect only the statements, keeping
        // body and return as logically distinct ranges.
        if matches!(lang.node_kind_for(&node_snapshot.node_type), Some(NodeKind::Body)) {
            if let Some(ret) = node_snapshot.children.iter().rev()
                .find(|c| matches!(lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)))
            {
                let last_non_ret = node_snapshot.children.iter().rev()
                    .find(|c| !matches!(lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)));
                let (end_row, end_col) = last_non_ret
                    .map(|c| (c.range.end_row, c.range.end_col))
                    .unwrap_or((ret.range.start_row, ret.range.start_col));
                range.end_row = end_row;
                range.end_col = end_col;
            }
        }

        let mut outline = Self::compute_outline(lang, &node_snapshot.children);

        // Suppress identifiers/names by matching their start position against exceptions.
        let exceptions = node.outline_exceptions();
        outline.retain(|item| {
            !exceptions.iter().any(|ex| {
                ex.start_row == item.range.start_row && ex.start_col == item.range.start_col
            })
        });

        // Expand variable_declaration: its single assignment_statement child is a transparent
        // wrapper — replace it with the assignment_statement's own children so that the
        // name (variable_list) and value (expression_list) appear directly in the outline.
        if node_snapshot.node_type == "variable_declaration"
            && outline.len() == 1
            && outline[0].node_type == "assignment_statement"
        {
            let wrapper = outline.remove(0);
            if let Ok(snap) = treesitter::snapshot(
                wrapper.range.start_row, wrapper.range.start_col,
                Some("assignment_statement"),
                Some((wrapper.range.start_row, wrapper.range.start_col)),
                Some((wrapper.range.end_row,   wrapper.range.end_col)),
            ) {
                let mut expanded = Self::compute_outline(lang, &snap.children);
                expanded.sort_by(|a, b| {
                    a.range.start_row.cmp(&b.range.start_row)
                        .then(a.range.start_col.cmp(&b.range.start_col))
                });
                outline.extend(expanded);
            }
        }

        // Flatten binary expressions (e.g. x + y -> [x, y]).
        navigation::binary_navigation::flatten_binary_outline(lang, &mut outline);

        // Stamp hotkey hints (e.g. [p] for parameters, [b] for body).
        let hints = node.keyed_outline_hints();
        for item in &mut outline {
            if let Some((_, key)) = hints.iter().find(|(r, _)| {
                r.start_row == item.range.start_row && r.start_col == item.range.start_col
            }) {
                item.hint_key = Some(key);
            }
        }

        if matches!(lang.node_kind_for(&node_snapshot.node_type), Some(NodeKind::Function)) {
            Self::enrich_function_outline(lang, &mut outline);
            Self::redirect_transparent_param_outline_item(lang, &mut outline);
        }

        let focused = FocusedNode {
            node_type, range, node, navigation, outline,
        };

        Ok(Some(focused))
    }

    fn enrich_function_outline(lang: crate::probe::language::Language, outline: &mut Vec<OutlineItem>) {
        let (body_range, body_node_type) = match outline.iter()
            .find(|i| matches!(lang.node_kind_for(&i.node_type), Some(NodeKind::Body)))
        {
            Some(i) => (i.range.clone(), i.node_type.clone()),
            None    => return,
        };

        let Ok(body_snap) = treesitter::snapshot(
            body_range.start_row, body_range.start_col,
            Some(&body_node_type),
            Some((body_range.start_row, body_range.start_col)),
            Some((body_range.end_row,   body_range.end_col)),
        ) else { return };

        let Some(ret) = body_snap.children.iter()
            .rev()
            .find(|c| matches!(lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)))
        else { return };

        let last_non_return = body_snap.children.iter()
            .rev()
            .find(|c| !matches!(lang.node_kind_for(&c.node_type), Some(NodeKind::ReturnStatement)));

        if let Some(idx) = outline.iter().position(|i| {
            matches!(lang.node_kind_for(&i.node_type), Some(NodeKind::Body))
        }) {
            match last_non_return {
                Some(last) => {
                    outline[idx].range.end_row = last.range.end_row;
                    outline[idx].range.end_col = last.range.end_col;
                }
                None => {
                    outline[idx].range.end_row = ret.range.start_row;
                    outline[idx].range.end_col = ret.range.start_col;
                }
            }
        }

        if outline.iter().any(|t| {
            t.range.start_row == ret.range.start_row && t.range.start_col == ret.range.start_col
        }) {
            return;
        }

        let label = ret.text.lines()
            .find(|l| !l.trim().is_empty())
            .map(|s| { let s = s.trim(); if s.len() > 16 { s[..16].to_string() } else { s.to_string() } })
            .unwrap_or_else(|| ret.node_type.clone());

        outline.push(OutlineItem {
            label,
            node_type: ret.node_type.clone(),
            category: outline::category_for(lang, &ret.node_type),
            range: ret.range.clone(),
            hint_key: Some("r"),
        });
        outline.sort_by(|a, b| a.range.start_row.cmp(&b.range.start_row).then(a.range.start_col.cmp(&b.range.start_col)));
    }

    /// Redirects any ParameterList outline item to its single inner child when the list
    /// is transparent (exactly 1 child). hint_key ("p") is preserved.
    /// No-op if the snapshot fails or the list has ≠ 1 child.
    fn redirect_transparent_param_outline_item(lang: crate::probe::language::Language, outline: &mut Vec<OutlineItem>) {
        for item in outline.iter_mut() {
            if !matches!(lang.node_kind_for(&item.node_type), Some(NodeKind::ParameterList)) {
                continue;
            }
            let Ok(snap) = treesitter::snapshot(
                item.range.start_row, item.range.start_col,
                Some(&item.node_type),
                Some((item.range.start_row, item.range.start_col)),
                Some((item.range.end_row,   item.range.end_col)),
            ) else { continue };

            if snap.children.len() != 1 { continue; }

            let inner = &snap.children[0];
            item.node_type = inner.node_type.clone();
            item.category  = outline::category_for(lang, &inner.node_type);
            item.range     = inner.range.clone();
            item.label     = inner.text.lines()
                .find(|l| !l.trim().is_empty())
                .map(|s| { let s = s.trim(); if s.len() > 16 { s[..16].to_string() } else { s.to_string() } })
                .unwrap_or_else(|| inner.node_type.clone());
            // hint_key ("p") is preserved from the earlier stamping step.
        }
    }
}

