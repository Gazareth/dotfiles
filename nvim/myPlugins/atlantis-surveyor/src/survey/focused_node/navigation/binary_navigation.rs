use crate::model::OutlineItem;
use crate::probe::language::Language;
use crate::probe::treesitter::{self, NodeOutline};
use crate::model::NavigationTarget;

/// Snapshots the outermost binary_expression and recursively flattens all nested
/// binary_expression nodes, returning a flat list of operand NavigationTargets.
pub fn gather_binary_siblings(lang: Language, root: &NodeOutline) -> Vec<NavigationTarget> {
    let Ok(snap) = treesitter::snapshot(
        root.range.start_row,
        root.range.start_col,
        Some("binary_expression"),
        Some((root.range.start_row, root.range.start_col)),
        Some((root.range.end_row,   root.range.end_col)),
    ) else { return vec![]; };

    let mut outline = super::super::FocusedNode::compute_outline(&snap.children);

    flatten_binary_outline(lang, &mut outline);

    outline.into_iter()
        .map(|item| NavigationTarget {
            node_type: item.node_type,
            classification: String::new(),
            range: item.range,
            key: None,
        })
        .collect()
}

/// Recursively expands binary_expression entries in an outline until only
/// non-binary operands remain.
pub(in crate::survey::focused_node) fn flatten_binary_outline(lang: Language, outline: &mut Vec<OutlineItem>) {
    loop {
        let Some(idx) = outline.iter().position(|item| {
            item.node_type == "binary_expression"
        }) else { break; };

        let item = outline.remove(idx);
        let Ok(snap) = treesitter::snapshot(
            item.range.start_row, item.range.start_col,
            Some("binary_expression"),
            Some((item.range.start_row, item.range.start_col)),
            Some((item.range.end_row,   item.range.end_col)),
        ) else { break; };

        let children = super::super::FocusedNode::compute_outline(&snap.children);
        outline.extend(children);
        outline.sort_by(|a, b| {
            a.range.start_row.cmp(&b.range.start_row)
                .then(a.range.start_col.cmp(&b.range.start_col))
        });
    }
}
