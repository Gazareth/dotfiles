//! Buffer / Tree-sitter probing.

pub mod language;

#[cfg(not(test))]
pub mod treesitter;

#[cfg(test)]
#[path = "treesitter/mock.rs"]
pub mod treesitter;
