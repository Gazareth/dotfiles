-- Test-only helpers: scratch buffers, Tree-sitter parse, cursor placement.

local M = {}

--- 0-based byte column of first occurrence of `needle` in `line` (plain search).
function M.col0(line, needle)
  local i = string.find(line, needle, 1, true)
  assert(i, "needle not in line: " .. needle)
  return i - 1
end

--- @param lines string[]
--- @param filetype string passed to |filetype| (e.g. "lua", "typescript")
--- @param lang string Tree-sitter language name for |vim.treesitter.start()|
--- @param row1 integer 1-based row
--- @param col0 integer 0-based byte column
--- @param fn fun(bufnr: integer)
function M.with_treesitter(lines, filetype, lang, row1, col0, fn)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
  vim.treesitter.start(buf, lang)
  local p = vim.treesitter.get_parser(buf, lang)
  if p then
    p:parse()
  end
  vim.api.nvim_win_set_cursor(0, { row1, col0 })
  fn(buf)
end

--- Lua buffer + parser (wrapper around |with_treesitter|).
function M.with_lua(lines, row1, col0, fn)
  return M.with_treesitter(lines, "lua", "lua", row1, col0, fn)
end

--- Returns true if Tree-sitter can attach `lang` in a scratch buffer (no throw if missing).
function M.has_parser(lang)
  local buf = vim.api.nvim_create_buf(true, true)
  local ok = pcall(vim.treesitter.start, buf, lang)
  if not ok then
    return false
  end
  return vim.treesitter.get_parser(buf, lang) ~= nil
end

return M
