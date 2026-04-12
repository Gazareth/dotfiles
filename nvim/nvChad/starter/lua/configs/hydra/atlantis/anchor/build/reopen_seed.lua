-- Stabilize cursor before anchor_build on same-depth reopen so the jump candidate
-- chain matches the outer anchor (e.g. after LSP rename left the cursor on the name).
local M = {}

function M.pack(node_info)
  if type(node_info) ~= "table" or not node_info.node then
    return nil
  end
  return {
    bufnr = node_info.bufnr or 0,
    row = (node_info.start_row or 0) + 1,
    col = node_info.start_col or 0,
  }
end

function M.apply(seed)
  if type(seed) ~= "table" then
    return
  end
  local bufnr = seed.bufnr
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  pcall(vim.api.nvim_set_current_buf, bufnr)
  pcall(vim.api.nvim_win_set_cursor, 0, { seed.row or 1, seed.col or 0 })
end

return M
