//! Single `luaeval` bridge: parser check, `get_node`, range, and text in one Lua expression.

use nvim_oxi::api;
use nvim_oxi::conversion::FromObject;
use nvim_oxi::{Dictionary, Object};

use crate::error::AtlantisError;

/// Monolithic expression to get node info from Tree-sitter
const LUA: &str = r#"(function(bufnr, row, col)
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok_parser or parser == nil then
    return { err = "no_parser" }
  end
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
  if node == nil then
    return { err = "no_node" }
  end
  local t = node:type()
  local sr, sc, er, ec = node:range()
  local ok_txt, txt = pcall(vim.treesitter.get_node_text, node, bufnr)
  return {
    node_type = t,
    start_row = sr,
    start_col = sc,
    end_row = er,
    end_col = ec,
    text = (ok_txt and txt) or "",
  }
end)(...)"#;

/// Return a `Dictionary` of node info or error code
pub fn get_node_info(bufnr: i32, row: u32, col: u32) -> Result<Dictionary, AtlantisError> {
    let oneline: String = LUA
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty())
        .collect::<Vec<_>>()
        .join(" ");

    let escaped = oneline.replace('\'', "''");
    let vimexpr = format!("luaeval('{escaped}', [{bufnr},{row},{col}])");

    let out: Object = api::eval(&vimexpr).map_err(|e| AtlantisError::Api(e.to_string()))?;

    Dictionary::from_object(out).map_err(|e| AtlantisError::Api(e.to_string()))
}
