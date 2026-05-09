//! `luaeval` query: single round-trip to Neovim that returns node type, range,
//! text, buffer filetype, and named child fields as a raw `Dictionary`.

use nvim_oxi::api;
use nvim_oxi::conversion::FromObject;
use nvim_oxi::{Array, Dictionary, Object};

use crate::error::AtlantisError;

const LUA: &str = r#"(function(row, col, target_type, target_start_row, target_start_col, target_end_row, target_end_col)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
  if not ok_parser or parser == nil then
    return { err = "no_parser" }
  end
  parser:parse()
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
  if node then
    local sr, sc = node:range()
    -- Smart snap: if the cursor is not at the start of the node, it might be on an
    -- unnamed separator or operator. Try to snap to the next named child on the same line.
    if sr < row or sc < col then
      for child in node:iter_children() do
        if child:named() then
          local csr, csc = child:range()
          if csr == row and csc > col then
            node = child
            break
          end
        end
      end
    end
  end

  if node == nil then
    return { err = "no_node" }
  end

  if target_type and target_start_row then
    while node do
      local sr, sc, er, ec = node:range()
      local start_ok = node:type() == target_type and sr == target_start_row and sc == target_start_col
      local end_ok = (target_end_row == nil) or (er == target_end_row and ec == target_end_col)
      if start_ok and end_ok then
        break
      end
      node = node:parent()
    end
    if not node then return { err = "target_not_found" } end
  end

  local t = node:type()
  local sr, sc, er, ec = node:range()
  local ok_txt, txt = pcall(vim.treesitter.get_node_text, node, bufnr)
  local ft = vim.bo[bufnr].filetype
  local fields = {}
  local children = {}
  for child, fname in node:iter_children() do
    if child:named() or fname ~= nil then
      local ok_ct, ct = pcall(vim.treesitter.get_node_text, child, bufnr)
      local csr, csc, cer, cec = child:range()
      local child_data = {
        node_type = child:type(),
        text = (ok_ct and ct) or "",
        start_row = csr,
        start_col = csc,
        end_row = cer,
        end_col = cec,
      }
      if fname then
        fields[fname] = child_data
      end
      table.insert(children, child_data)
    end
  end
  local siblings = {}
  local p = node:parent()
  if p then
    for sibling, sfname in p:iter_children() do
      if sibling:named() or sfname ~= nil then
        local ssr, ssc, ser, sec = sibling:range()
        table.insert(siblings, {
          node_type = sibling:type(),
          start_row = ssr, start_col = ssc, end_row = ser, end_col = sec
        })
      end
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
    children = children,
    siblings = siblings,
  }
end)(_A[1], _A[2], _A[3], _A[4], _A[5], _A[6], _A[7])"#;

pub fn call(
    row: u32,
    col: u32,
    target_type: Option<&str>,
    target_start: Option<(u32, u32)>,
    target_end: Option<(u32, u32)>,
) -> Result<Dictionary, AtlantisError> {
    let oneline: String = LUA
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty())
        .collect::<Vec<_>>()
        .join(" ");

    let escaped = oneline.replace('\'', "''");

    let type_val = target_type.map(Object::from).unwrap_or(Object::nil());
    let (sr_val, sc_val) = match target_start {
        Some((r, c)) => (Object::from(r as i64), Object::from(c as i64)),
        None => (Object::nil(), Object::nil()),
    };
    let (er_val, ec_val) = match target_end {
        Some((r, c)) => (Object::from(r as i64), Object::from(c as i64)),
        None => (Object::nil(), Object::nil()),
    };

    let args = Array::from_iter([
        Object::from(row as i64),
        Object::from(col as i64),
        type_val,
        sr_val,
        sc_val,
        er_val,
        ec_val,
    ]);

    let luaeval_args = Array::from_iter([
        Object::from(escaped),
        Object::from(args),
    ]);

    let out = api::call_function("luaeval", luaeval_args).map_err(|e| AtlantisError::Api(e.to_string()))?;

    Dictionary::from_object(out).map_err(|e| AtlantisError::Api(e.to_string()))
}
