use nvim_oxi::api;
use nvim_oxi::Dictionary;

use crate::survey;

pub fn run(bufnr: i32, ancestry: Dictionary) -> survey::AtlantisNode {
    let bufnr = if bufnr == 0 {
        api::get_current_buf().handle()
    } else {
        bufnr
    };

    survey::build::build_from_ancestry(bufnr, ancestry)
}
