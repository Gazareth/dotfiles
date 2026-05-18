mod actions;
pub(crate) mod ancestry;
pub(crate) mod comment;
mod navigation;
mod outline;

#[cfg(not(test))]
use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::lang::NodeKind;
use crate::model::node::{NodeRange, RawNode};
use crate::model::{AtlantisNode, NavigationTarget, OutlineItem};
use crate::probe::treesitter::{NodeOutline, SnapshotChild};
use crate::probe::language::Language;
use self::comment::{is_comment_kind, preceding_comment_range};

use self::ancestry::NodeAncestry;

pub use self::navigation::NavigationInfo;

/// Snapshot-fetching callback threaded through the survey pipeline.
/// Production: wraps `treesitter::snapshot`. Tests: pops from a local `Vec`.
pub(crate) type Fetch<'a> = dyn FnMut(u32, u32, Option<&str>, Option<(u32, u32)>, Option<(u32, u32)>)
    -> Result<crate::probe::treesitter::NodeSnapshot, AtlantisError> + 'a;


// ── FocusedNode ───────────────────────────────────────────────────────

/// A resolved node ready to be turned into a `SurveyResult`.
pub struct FocusedNode {
    pub node_type:            String,
    pub range:                NodeRange,
    pub node:                 AtlantisNode,
    pub navigation:           NavigationInfo,
    pub outline:              Vec<OutlineItem>,
    /// Range of consecutive comment lines immediately above this node (Function/Assignment/Loop only).
    pub comment_range:        Option<NodeRange>,
    /// When the focused node is a comment, the first recognised statement below the block.
    pub associated_statement: Option<NavigationTarget>,
}

struct CommentInfo {
    block_range:          NodeRange,
    associated_statement: Option<NavigationTarget>,
}

impl CommentInfo {
    /// Called when the focused node IS a comment. Expands to the full consecutive
    /// comment block (including adjacent comment siblings above and below), then
    /// finds the first recognised statement after the block.
    fn from_comment_focus(snapshot: &crate::probe::treesitter::NodeSnapshot, lang: Language) -> Self {
        let Some(pos) = snapshot.siblings.iter().position(|s| {
            s.range.start_row == snapshot.range.start_row
                && s.range.start_col == snapshot.range.start_col
        }) else {
            return Self { block_range: snapshot.range.clone(), associated_statement: None };
        };

        let above: Vec<&SnapshotChild> = {
            let mut v = Vec::new();
            let mut next_start_row = snapshot.range.start_row;
            for s in snapshot.siblings[..pos].iter().rev() {
                if !is_comment_kind(&s.node_type) { break; }
                if s.range.end_row + 1 != next_start_row { break; }
                v.push(s);
                next_start_row = s.range.start_row;
            }
            v
        };
        let below: Vec<&SnapshotChild> = {
            let mut v = Vec::new();
            let mut prev_end_row = snapshot.range.end_row;
            for s in snapshot.siblings[pos + 1..].iter() {
                if !is_comment_kind(&s.node_type) { break; }
                if s.range.start_row != prev_end_row + 1 { break; }
                v.push(s);
                prev_end_row = s.range.end_row;
            }
            v
        };

        let start = above.last().map(|s| &s.range).unwrap_or(&snapshot.range);
        let end   = below.last().map(|s| &s.range).unwrap_or(&snapshot.range);

        let block_range = NodeRange {
            start_row: start.start_row, start_col: start.start_col,
            end_row:   end.end_row,     end_col:   end.end_col,
        };

        let block_end_row = end.end_row;
        let associated_statement = snapshot.siblings[pos..]
            .iter()
            .skip_while(|s| is_comment_kind(&s.node_type))
            .find(|s| lang.node_kind_for(&s.node_type).is_some() && s.range.start_row == block_end_row + 1)
            .map(|s| NavigationTarget {
                node_type:      s.node_type.clone(),
                classification: lang.classify(RawNode::from(s), None).classification_name(),
                range:          s.range.clone(),
                key:            None,
                comment_range:  None,
            });

        Self { block_range, associated_statement }
    }
}

impl FocusedNode {
    #[cfg(not(test))]
    pub fn from_raw(
        raw:         &Dictionary,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<Option<Self>, AtlantisError> {
        let ancestry = NodeAncestry::parse(raw)?;
        Self::from_ancestry(ancestry, target_hint)
    }

    /// Production entry point: fetches snapshots via the real Tree-sitter probe.
    #[cfg(not(test))]
    pub fn from_ancestry(
        ancestry:    NodeAncestry,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<Option<Self>, AtlantisError> {
        Self::from_ancestry_inner(ancestry, target_hint, &mut crate::probe::treesitter::snapshot)
    }

    /// Test entry point: consumes snapshots from a pre-supplied list in order.
    #[cfg(test)]
    pub fn from_ancestry(
        ancestry:    NodeAncestry,
        target_hint: Option<(&str, u32, u32)>,
        snapshots:   Vec<crate::probe::treesitter::NodeSnapshot>,
    ) -> Result<Option<Self>, AtlantisError> {
        let mut queue = std::collections::VecDeque::from(snapshots);
        Self::from_ancestry_inner(ancestry, target_hint, &mut |_, _, _, _, _| {
            queue.pop_front().ok_or(AtlantisError::NoNode)
        })
    }

    fn from_ancestry_inner(
        ancestry:    NodeAncestry,
        target_hint: Option<(&str, u32, u32)>,
        fetch:       &mut Fetch<'_>,
    ) -> Result<Option<Self>, AtlantisError> {
        let lang = ancestry.language();
        let all: Vec<&NodeOutline> = ancestry.all().collect();

        let focus_idx = match ancestry.find_focus_idx(target_hint) {
            Ok(idx) => idx,
            Err(_)  => return Ok(None),
        };

        let focus_node_outline = all[focus_idx];
        let parent_ref = all.get(focus_idx + 1).copied();

        let node_snapshot = fetch(
            focus_node_outline.range.start_row,
            focus_node_outline.range.start_col,
            Some(&focus_node_outline.node_type),
            Some((focus_node_outline.range.start_row, focus_node_outline.range.start_col)),
            Some((focus_node_outline.range.end_row,   focus_node_outline.range.end_col)),
        )?;

        let node       = lang.classify(RawNode::from(&node_snapshot), parent_ref);
        let navigation = NavigationInfo::from_snapshot_inner(lang, &all, focus_idx, &node_snapshot, fetch);
        let node_type  = node_snapshot.node_type.clone();
        let mut range  = node_snapshot.range.clone();

        // When the focus is a Body, trim its range to exclude any trailing return statement.
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

        let mut outline = if matches!(node, AtlantisNode::Comment) {
            vec![]
        } else {
            Self::compute_outline(lang, &node_snapshot.children)
        };

        let exceptions = node.outline_exceptions();
        outline.retain(|item| {
            !exceptions.iter().any(|ex| {
                ex.start_row == item.range.start_row && ex.start_col == item.range.start_col
            })
        });

        // Expand variable_declaration: its single assignment_statement child is a transparent
        // wrapper — replace it with the assignment_statement's own children.
        if node_snapshot.node_type == "variable_declaration"
            && outline.len() == 1
            && outline[0].node_type == "assignment_statement"
        {
            let wrapper = outline.remove(0);
            if let Ok(snap) = fetch(
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

        navigation::binary_navigation::flatten_binary_outline(lang, &mut outline, fetch);

        let hints = node.keyed_outline_hints();
        for item in &mut outline {
            if let Some((_, key)) = hints.iter().find(|(r, _)| {
                r.start_row == item.range.start_row && r.start_col == item.range.start_col
            }) {
                item.hint_key = Some(key);
            }
        }

        if matches!(lang.node_kind_for(&node_snapshot.node_type), Some(NodeKind::Function)) {
            Self::enrich_function_outline(lang, &mut outline, fetch);
            Self::redirect_transparent_param_outline_item(lang, &mut outline, fetch);
        }

        let is_comment = matches!(node, AtlantisNode::Comment);

        let (comment_range, associated_statement) = if is_comment {
            let info = CommentInfo::from_comment_focus(&node_snapshot, lang);
            range = info.block_range.clone();
            (None, info.associated_statement)
        } else {
            let is_commentable = matches!(
                lang.node_kind_for(&node_snapshot.node_type),
                Some(NodeKind::Function | NodeKind::Assignment | NodeKind::Loop)
            );
            let cr = if is_commentable {
                let pos = node_snapshot.siblings.iter().position(|s| {
                    s.range.start_row == node_snapshot.range.start_row
                        && s.range.start_col == node_snapshot.range.start_col
                });
                pos.and_then(|p| preceding_comment_range(&node_snapshot.siblings, p))
            } else {
                None
            };
            (cr, None)
        };

        let focused = FocusedNode {
            node_type, range, node, navigation, outline,
            comment_range, associated_statement,
        };

        Ok(Some(focused))
    }

    fn enrich_function_outline(
        lang:    crate::probe::language::Language,
        outline: &mut Vec<OutlineItem>,
        fetch:   &mut Fetch<'_>,
    ) {
        let (body_range, body_node_type) = match outline.iter()
            .find(|i| matches!(lang.node_kind_for(&i.node_type), Some(NodeKind::Body)))
        {
            Some(i) => (i.range.clone(), i.node_type.clone()),
            None    => return,
        };

        let Ok(body_snap) = fetch(
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
    fn redirect_transparent_param_outline_item(
        lang:    crate::probe::language::Language,
        outline: &mut [OutlineItem],
        fetch:   &mut Fetch<'_>,
    ) {
        for item in outline.iter_mut() {
            if !matches!(lang.node_kind_for(&item.node_type), Some(NodeKind::ParameterList)) {
                continue;
            }
            let Ok(snap) = fetch(
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
        }
    }
}
