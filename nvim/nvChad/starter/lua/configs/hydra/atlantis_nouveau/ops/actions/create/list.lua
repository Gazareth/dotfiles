local M = {}

-- Assumes result.range spans the full list including delimiters, e.g. (a, b, c).
-- r.end_col is exclusive, so r.end_col - 1 lands at the closing delimiter.

function M.first(result)
  local r = result.range
  vim.api.nvim_buf_set_text(result.bufnr, r.start_row, r.start_col + 1,
                                          r.start_row, r.start_col + 1, { ", " })
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col + 1 })
  vim.schedule(function() vim.cmd("startinsert") end)
end

function M.last(result)
  local r = result.range
  vim.api.nvim_buf_set_text(result.bufnr, r.end_row, r.end_col - 1,
                                          r.end_row, r.end_col - 1, { ", " })
  vim.api.nvim_win_set_cursor(0, { r.end_row + 1, r.end_col + 1 })
  vim.schedule(function() vim.cmd("startinsert") end)
end

return M
