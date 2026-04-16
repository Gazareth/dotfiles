use nvim_oxi::api;

use crate::prepare;

/// `bufnr == 0` means current buffer. `row` / `col` are **0-based** (match `vim.treesitter.get_node` `pos`).
pub fn run(bufnr: i32, row: i64, col: i64) -> crate::anchor::AnchorInfo {
    let bufnr = if bufnr == 0 {
        api::get_current_buf().handle()
    } else {
        bufnr
    };

    let row = u32::try_from(row.max(0)).unwrap_or(0);
    let col = u32::try_from(col.max(0)).unwrap_or(0);

    prepare::build_anchor_info(bufnr, row, col)
}
