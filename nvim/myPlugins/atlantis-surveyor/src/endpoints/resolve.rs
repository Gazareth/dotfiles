use nvim_oxi::api;
use nvim_oxi::Dictionary;

use crate::survey::SurveyResult;

pub fn run(bufnr: i32, ancestry: Dictionary) -> Vec<SurveyResult> {
    let bufnr = if bufnr == 0 {
        api::get_current_buf().handle()
    } else {
        bufnr
    };

    SurveyResult::generate(bufnr, ancestry)
}
