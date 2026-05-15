//! atlantis_surveyor — Rust probe layer for Atlantis (Neovim + nvim-oxi).

mod action;
mod error;
mod model;
mod probe;
mod survey;

#[cfg(test)]
mod tests;

#[cfg(not(test))]
use nvim_oxi::{Dictionary, Function};

#[cfg(not(test))]
#[nvim_oxi::plugin]
fn atlantis_surveyor() -> Function<(Dictionary, Option<String>), survey::SurveyResult> {
    Function::from_fn(|(ancestry, mode)| survey::SurveyResult::generate(ancestry, mode))
}
