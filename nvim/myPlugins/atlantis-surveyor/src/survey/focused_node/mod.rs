mod actions;
pub(crate) mod ancestry;
mod navigation;
mod outline;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
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
        let range      = node_snapshot.range.clone();

        let mut outline = Self::compute_outline(&node_snapshot.children);

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
                let mut expanded = Self::compute_outline(&snap.children);
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

        let focused = FocusedNode {
            node_type, range, node, navigation, outline,
        };

        Ok(Some(focused))
    }
}

