use nvim_oxi::api;

use crate::survey::SurveyResult;

/// `bufnr == 0` means current buffer. `row` / `col` are **0-based** (match `vim.treesitter.get_node` `pos`).
pub fn run(
    bufnr: i32,
    row: i64,
    col: i64,
    target_type: Option<String>,
    target_row: Option<i64>,
    target_col: Option<i64>
) -> Vec<SurveyResult> {
    let bufnr = if bufnr == 0 {
        api::get_current_buf().handle()
    } else {
        bufnr
    };

    let row = u32::try_from(row.max(0)).unwrap_or(0);
    let col = u32::try_from(col.max(0)).unwrap_or(0);

    let target_start = if let (Some(r), Some(c)) = (target_row, target_col) {
        Some((r as u32, c as u32))
    } else {
        None
    };

    SurveyResult::at_position(bufnr, row, col, target_type.as_deref(), target_start)
}
