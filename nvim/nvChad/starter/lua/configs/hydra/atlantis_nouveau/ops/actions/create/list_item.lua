local M = {}

-- Only call M.before when nav.prev_sibling exists (not first item).
function M.before(result)
  local r = result.range
  vim.api.nvim_buf_set_text(result.bufnr, r.start_row, r.start_col,
                                          r.start_row, r.start_col, { ", " })
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
  vim.schedule(function() vim.cmd("startinsert") end)
end

function M.after(result)
  local r = result.range
  vim.api.nvim_buf_set_text(result.bufnr, r.end_row, r.end_col,
                                          r.end_row, r.end_col, { ", " })
  vim.api.nvim_win_set_cursor(0, { r.end_row + 1, r.end_col + 2 })
  vim.schedule(function() vim.cmd("startinsert") end)
end

return M
