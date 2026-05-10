use std::cmp::Ordering;

use crate::model::{AtlantisNode, OutlineItem};

use crate::probe::treesitter::SnapshotChild;

use super::FocusedNode;

impl FocusedNode {
    pub(in crate::survey) fn compute_outline(
        children: &[SnapshotChild],
        _classify: impl Fn(&SnapshotChild) -> AtlantisNode,
    ) -> Vec<OutlineItem> {
        let mut sorted_children = children.to_vec();
        sorted_children.sort_by(|a, b| {
            match a.range.start_row.cmp(&b.range.start_row) {
                Ordering::Equal => a.range.start_col.cmp(&b.range.start_col),
                other => other,
            }
        });

        sorted_children.into_iter()
            .map(|child| {
                let label = child.text
                    .lines()
                    .find(|l| !l.trim().is_empty())
                    .map(|s| {
                        let s = s.trim();
                        if s.len() > 16 { s[..16].to_string() } else { s.to_string() }
                    })
                    .unwrap_or_else(|| child.node_type.clone());
                OutlineItem { label, node_type: child.node_type.clone(), range: child.range.clone() }
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::FocusedNode;
    use crate::model::{AtlantisNode, node::NodeRange};
    use crate::model::node::RawNode;
    use crate::probe::language::Language;
    use crate::probe::treesitter::SnapshotChild;


    #[test]
    fn compute_outline_preserves_block_child_order() {
        let children = vec![
            SnapshotChild {
                node_type: "variable_declaration".into(),
                text: "local a = 1".into(),
                range: NodeRange { start_row: 1, start_col: 2, end_row: 1, end_col: 12 },
            },
            SnapshotChild {
                node_type: "variable_declaration".into(),
                text: "local b = 2".into(),
                range: NodeRange { start_row: 2, start_col: 2, end_row: 2, end_col: 12 },
            },
            SnapshotChild {
                node_type: "if_statement".into(),
                text: "if a == 1 then\n  return b\nend".into(),
                range: NodeRange { start_row: 3, start_col: 2, end_row: 5, end_col: 5 },
            },
        ];

        let outline = FocusedNode::compute_outline(&children, |child: &SnapshotChild| {
            AtlantisNode::from_raw(RawNode::from(child), &Language::Lua)
        });

        assert_eq!(outline.len(), 3);
        assert_eq!(outline[0].label, "local a = 1");
        assert_eq!(outline[1].label, "local b = 2");
        assert_eq!(outline[2].label, "if a == 1 then");
    }

    #[test]
    fn compute_outline_includes_children_regardless_of_field_names() {
        // In the new query logic, 'children' contains ALL named children.
        // This test verifies that compute_outline correctly handles a mix of nodes.
        let children = vec![
            SnapshotChild {
                node_type: "parameters".into(),
                text: "(a, b)".into(),
                range: NodeRange { start_row: 1, start_col: 10, end_row: 1, end_col: 16 },
            },
            SnapshotChild {
                node_type: "block".into(),
                text: "{\n  return 1\n}".into(),
                range: NodeRange { start_row: 1, start_col: 17, end_row: 3, end_col: 1 },
            },
        ];

        let outline = FocusedNode::compute_outline(&children, |child: &SnapshotChild| {
            AtlantisNode::from_raw(RawNode::from(child), &Language::Lua)
        });

        assert_eq!(outline.len(), 2);
        assert_eq!(outline[0].label, "(a, b)");
        assert_eq!(outline[1].label, "{");
    }
}
