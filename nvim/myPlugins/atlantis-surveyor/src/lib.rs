//! atlantis_surveyor — Rust probe layer for Atlantis (Neovim + nvim-oxi).

mod action;
mod anchor;
mod constants;
mod endpoints;
mod error;
mod prepare;
mod probe;

use nvim_oxi::{Dictionary, Function, Object};

#[nvim_oxi::plugin]
fn atlantis_surveyor() -> Dictionary {
    let anchor = Function::from_fn(
        |(bufnr, row, col): (i32, i64, i64)| endpoints::anchor::run(bufnr, row, col),
    );

    Dictionary::from_iter([("anchor", Object::from(anchor))])
}
