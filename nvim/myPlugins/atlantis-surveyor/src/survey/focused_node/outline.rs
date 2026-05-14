use std::cmp::Ordering;

use crate::model::OutlineItem;
use crate::model::lang::NodeKind;
use crate::probe::language::Language;

use crate::probe::treesitter::SnapshotChild;

use super::FocusedNode;

/// Maps a Tree-sitter node type to the coarse classification used by the UI to
/// bucket outline items into headings. Falls back to "other" for any node type
/// the language doesn't classify into one of the four named buckets.
pub(in crate::survey) fn category_for(lang: Language, node_type: &str) -> &'static str {
    match lang.node_kind_for(node_type) {
        Some(NodeKind::Assignment)  => "assignment",
        Some(NodeKind::Conditional) => "conditional",
        Some(NodeKind::Loop)        => "loop",
        Some(NodeKind::Function)    => "function",
        _                           => "other",
    }
}

impl FocusedNode {
    pub(in crate::survey) fn compute_outline(
        lang: Language,
        children: &[SnapshotChild],
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
                let category = category_for(lang, &child.node_type);
                OutlineItem {
                    label,
                    node_type: child.node_type.clone(),
                    category,
                    range: child.range.clone(),
                    hint_key: None,
                }
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::FocusedNode;
    use crate::model::node::NodeRange;
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

        let outline = FocusedNode::compute_outline(Language::Lua, &children);

        assert_eq!(outline.len(), 3);
        assert_eq!(outline[0].label, "local a = 1");
        assert_eq!(outline[0].category, "assignment");
        assert_eq!(outline[1].label, "local b = 2");
        assert_eq!(outline[1].category, "assignment");
        assert_eq!(outline[2].label, "if a == 1 then");
        assert_eq!(outline[2].category, "conditional");
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

        let outline = FocusedNode::compute_outline(Language::Lua, &children);

        assert_eq!(outline.len(), 2);
        assert_eq!(outline[0].label, "(a, b)");
        assert_eq!(outline[0].category, "other");
        assert_eq!(outline[1].label, "{");
        assert_eq!(outline[1].category, "other");
    }

    #[test]
    fn compute_outline_categorises_loops_functions_and_calls() {
        let children = vec![
            SnapshotChild {
                node_type: "for_numeric_statement".into(),
                text: "for i = 1, 10 do".into(),
                range: NodeRange { start_row: 0, start_col: 0, end_row: 2, end_col: 3 },
            },
            SnapshotChild {
                node_type: "while_statement".into(),
                text: "while x do".into(),
                range: NodeRange { start_row: 3, start_col: 0, end_row: 5, end_col: 3 },
            },
            SnapshotChild {
                node_type: "function_declaration".into(),
                text: "function foo()".into(),
                range: NodeRange { start_row: 6, start_col: 0, end_row: 8, end_col: 3 },
            },
            SnapshotChild {
                node_type: "function_call".into(),
                text: "print(\"hi\")".into(),
                range: NodeRange { start_row: 9, start_col: 0, end_row: 9, end_col: 11 },
            },
        ];

        let outline = FocusedNode::compute_outline(Language::Lua, &children);

        assert_eq!(outline[0].category, "loop");
        assert_eq!(outline[1].category, "loop");
        assert_eq!(outline[2].category, "function");
        // Function calls aren't a top-level bucket; they fall into "other".
        assert_eq!(outline[3].category, "other");
    }
}
