-- Test-only helpers: scratch Lua buffers, Tree-sitter parse, cursor placement.

local M = {}

--- 0-based byte column of first occurrence of `needle` in `line` (plain search).
function M.col0(line, needle)
  local i = string.find(line, needle, 1, true)
  assert(i, "needle not in line: " .. needle)
  return i - 1
end

--- @param lines string[]
--- @param row1 integer 1-based row
--- @param col0 integer 0-based byte column
--- @param fn fun(bufnr: integer)
function M.with_lua(lines, row1, col0, fn)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_option_value("filetype", "lua", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
  vim.treesitter.start(buf, "lua")
  local p = vim.treesitter.get_parser(buf, "lua")
  if p then
    p:parse()
  end
  vim.api.nvim_win_set_cursor(0, { row1, col0 })
  fn(buf)
end

return M
