//! Raw `vim.treesitter` bridge via `luaeval` / `api::eval` (Neovim’s parse tree only).

mod node;

pub use node::capture_raw_dictionary;
