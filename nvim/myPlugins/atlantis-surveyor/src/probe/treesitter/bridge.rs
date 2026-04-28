//! `luaeval` bridge: single round-trip to Neovim that returns node type, range,
//! text, buffer filetype, and named child fields as a raw `Dictionary`.

use nvim_oxi::api;
use nvim_oxi::conversion::FromObject;
use nvim_oxi::{Dictionary, Object};

use crate::error::AtlantisError;

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
  local ft = vim.bo[bufnr].filetype
  local fields = {}
  for i = 0, node:child_count() - 1 do
    local child = node:child(i)
    local fname = node:field_name_for_child(i)
    if fname and child and child:is_named() then
      local ok_ct, ct = pcall(vim.treesitter.get_node_text, child, bufnr)
      local csr, csc, cer, cec = child:range()
      fields[fname] = {
        node_type = child:type(),
        text = (ok_ct and ct) or "",
        start_row = csr,
        start_col = csc,
        end_row = cer,
        end_col = cec,
      }
    end
  end
  return {
    node_type = t,
    start_row = sr,
    start_col = sc,
    end_row = er,
    end_col = ec,
    text = (ok_txt and txt) or "",
    filetype = ft,
    fields = fields,
  }
end)(...)"#;

pub fn call(bufnr: i32, row: u32, col: u32) -> Result<Dictionary, AtlantisError> {
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
