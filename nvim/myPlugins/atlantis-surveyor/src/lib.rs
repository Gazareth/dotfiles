//! atlantis_surveyor — Rust probe layer for Atlantis (Neovim + nvim-oxi).

mod action;
mod endpoints;
mod error;
mod model;
mod probe;
mod survey;

use nvim_oxi::{Dictionary, Function, Object};

#[nvim_oxi::plugin]
fn atlantis_surveyor() -> Dictionary {
    let node = Function::from_fn(
        |(bufnr, row, col, target_type, target_row, target_col): (i32, i64, i64, Option<String>, Option<i64>, Option<i64>)| -> Vec<survey::SurveyResult> {
            endpoints::node::run(bufnr, row, col, target_type, target_row, target_col)
        },
    );

    let resolve = Function::from_fn(
        |(bufnr, ancestry): (i32, Dictionary)| -> Vec<survey::SurveyResult> {
            endpoints::resolve::run(bufnr, ancestry)
        },
    );

    Dictionary::from_iter([
        ("node",    Object::from(node)),
        ("resolve", Object::from(resolve)),
    ])
}
