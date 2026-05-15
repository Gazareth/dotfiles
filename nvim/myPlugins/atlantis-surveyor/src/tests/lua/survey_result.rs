// Verifies SurveyResult::from(FocusedNode) produces the Ok variant with correct fields,
// and that the Err variant is constructible.

use crate::tests::lua::*;
use crate::survey::focused_node::FocusedNode;
use crate::survey::focused_node::ancestry::NodeAncestry;
use crate::survey::{SurveyResult, AtlantisNode};
use crate::probe::treesitter::NodeOutline;
use crate::probe::language::Language;
use crate::model::node::NodeRange;

fn range(sr: u32, sc: u32, er: u32, ec: u32) -> NodeRange {
    NodeRange { start_row: sr, start_col: sc, end_row: er, end_col: ec }
}

#[test]
fn survey_result_from_focused_node_produces_ok_variant() {
    let fn_range = range(0, 0, 3, 3);
    let p_range  = range(0, 12, 0, 14);
    let b_range  = range(1, 0, 2, 3);

    let focus = NodeOutline::new("function_declaration", fn_range.clone());
    let root  = NodeOutline::new("chunk",                fn_range.clone());
    let ancestry = NodeAncestry::new_test(vec![focus], root, Language::Lua);

    let focused = FocusedNode::from_ancestry(ancestry, None, vec![
        snap("function_declaration")
            .range(fn_range.start_row, fn_range.start_col, fn_range.end_row, fn_range.end_col)
            .field_ranged("parameters", "()", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
            .field_ranged("block",      "...", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .child_ranged("parameters", "()", p_range.start_row, p_range.start_col, p_range.end_row, p_range.end_col)
            .child_ranged("block",      "...", b_range.start_row, b_range.start_col, b_range.end_row, b_range.end_col)
            .build(),
    ]).unwrap().unwrap();

    let result = SurveyResult::from(focused);

    match result {
        SurveyResult::Ok { node_type, range, node, .. } => {
            assert_eq!(node_type, "function_declaration");
            assert_eq!(range, fn_range);
            assert!(matches!(node, AtlantisNode::Recognised(_)));
        }
        SurveyResult::Err { message } => panic!("expected Ok, got Err: {message}"),
    }
}

#[test]
fn survey_result_err_variant_is_constructible() {
    let result = SurveyResult::Err { message: "test error".into() };
    assert!(matches!(result, SurveyResult::Err { .. }));
}
