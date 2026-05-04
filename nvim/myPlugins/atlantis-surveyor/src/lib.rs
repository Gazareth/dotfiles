//! atlantis_surveyor — Rust probe layer for Atlantis (Neovim + nvim-oxi).

mod action;
mod error;
mod model;
mod probe;
mod survey;

#[cfg(test)]
mod tests;

use nvim_oxi::{Dictionary, Function};

#[cfg(not(test))]
#[nvim_oxi::plugin]
fn atlantis_surveyor() -> Function<Dictionary, survey::SurveyResult> {
    Function::from_fn(survey::SurveyResult::generate)
}
