//! atlantis_surveyor — Rust probe layer for Atlantis (Neovim + nvim-oxi).

mod action;
mod error;
mod model;
mod probe;
mod survey;

use nvim_oxi::{Dictionary, Function};

#[nvim_oxi::plugin]
fn atlantis_surveyor() -> Function<Dictionary, survey::SurveyResult> {
    Function::from_fn(survey::SurveyResult::generate)
}
