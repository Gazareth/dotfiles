use crate::model::OutlineItem;
use crate::probe::language::Language;
use crate::probe::treesitter;

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
