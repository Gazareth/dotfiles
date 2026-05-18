use crate::model::node::NodeRange;
use crate::probe::treesitter::SnapshotChild;

pub fn is_comment_kind(kind: &str) -> bool {
    kind.contains("comment")
}

/// Scan backwards through `children` from `focus_pos`, collecting consecutive
/// comment entries immediately above the node at that position.
/// A blank line (gap between `end_row + 1` and the next `start_row`) breaks the scan.
/// Returns their combined range, or `None` if there are no directly adjacent preceding comments.
pub fn preceding_comment_range(children: &[SnapshotChild], focus_pos: usize) -> Option<NodeRange> {
    if focus_pos == 0 {
        return None;
    }

    let mut preceding = Vec::new();
    let mut next_start_row = children[focus_pos].range.start_row;

    for child in children[..focus_pos].iter().rev() {
        if !is_comment_kind(&child.node_type) { break; }
        if child.range.end_row + 1 != next_start_row { break; }
        preceding.push(child);
        next_start_row = child.range.start_row;
    }

    if preceding.is_empty() {
        return None;
    }

    Some(NodeRange {
        start_row: preceding.last().unwrap().range.start_row,
        start_col: preceding.last().unwrap().range.start_col,
        end_row:   preceding.first().unwrap().range.end_row,
        end_col:   preceding.first().unwrap().range.end_col,
    })
}
