local M = {}

function M.before(result)
  local r = result.range
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, 0 })
  vim.schedule(function() vim.cmd("normal! O") end)
end

function M.after(result)
  local r = result.range
  vim.api.nvim_win_set_cursor(0, { r.end_row + 1, 0 })
  vim.schedule(function() vim.cmd("normal! o") end)
end

return M
