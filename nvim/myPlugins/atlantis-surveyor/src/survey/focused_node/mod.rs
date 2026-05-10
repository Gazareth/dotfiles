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

        let outline = Self::compute_outline(
            &node_snapshot.children,
            |raw| lang.classify(raw.into(), parent_ref),
        );

        // Stamp hint_key on any outline item whose range matches a keyed NavigationTarget.
        //
        // A "transparent wrapper" item is one where fewer hints match at its exact start
        // position than exist in total, but ALL hints are contained within its range.
        // In that case we expand the item one level and stamp the grandchildren instead.
        // Example: variable_declaration → outline has [assignment_statement]; lhs hint
        // shares the same start as assignment_statement (both start at col 6), but value
        // hint is deeper. Without expansion only [n] would appear; expansion yields
        // [variable_list → n] and [expression_list → v].
        let hints = node.keyed_outline_hints();
        let outline = if hints.is_empty() {
            outline
        } else {
            let mut result: Vec<OutlineItem> = Vec::with_capacity(outline.len());
            for mut item in outline {
                let direct_count = hints.iter().filter(|(r, _)| {
                    r.start_row == item.range.start_row && r.start_col == item.range.start_col
                }).count();

                let all_contained = hints.iter().all(|(r, _)| {
                    (r.start_row > item.range.start_row
                        || (r.start_row == item.range.start_row && r.start_col >= item.range.start_col))
                    && (r.end_row < item.range.end_row
                        || (r.end_row == item.range.end_row && r.end_col <= item.range.end_col))
                });

                // Wrapper: at least one hint is deeper than this item's start, yet all
                // hints live inside it. Expand one level and stamp the grandchildren.
                let is_wrapper = direct_count < hints.len() && all_contained;

                if is_wrapper {
                    if let Ok(inner_snap) = treesitter::snapshot(
                        item.range.start_row, item.range.start_col,
                        Some(&item.node_type),
                        Some((item.range.start_row, item.range.start_col)),
                        Some((item.range.end_row,   item.range.end_col)),
                    ) {
                        let mut expanded = Self::compute_outline(
                            &inner_snap.children,
                            |raw| lang.classify(raw.into(), parent_ref),
                        );
                        for gc in &mut expanded {
                            if let Some((_, key)) = hints.iter().find(|(r, _)| {
                                r.start_row == gc.range.start_row && r.start_col == gc.range.start_col
                            }) {
                                gc.hint_key = Some(key);
                            }
                        }
                        result.extend(expanded);
                        continue;
                    }
                }

                // Direct match for non-wrapper items.
                if let Some((_, key)) = hints.iter().find(|(r, _)| {
                    r.start_row == item.range.start_row && r.start_col == item.range.start_col
                }) {
                    item.hint_key = Some(key);
                }
                result.push(item);
            }
            result
        };

        let focused = FocusedNode {
            node_type, range, node, navigation, outline,
        };

        Ok(Some(focused))
    }
}

