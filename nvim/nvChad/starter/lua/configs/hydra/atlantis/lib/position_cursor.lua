-- Move the editor cursor to the start of a node_info payload (buffer + row/col).
local M = {}

function M.at_node_info(node_info)
  if type(node_info) ~= "table" or not node_info.node then
    return
  end

  local ok, err = pcall(function()
    if node_info.bufnr and vim.api.nvim_buf_is_valid(node_info.bufnr) then
      vim.api.nvim_set_current_buf(node_info.bufnr)
    end

    local row = (node_info.start_row or 0) + 1
    local col = node_info.start_col or 0
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.cmd("normal! zz")
  end)

  if not ok then
    vim.notify("Failed to position cursor at anchor: " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
