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
        |(bufnr, row, col): (i32, i64, i64)| endpoints::node::run(bufnr, row, col),
    );

    Dictionary::from_iter([("node", Object::from(node))])
}
