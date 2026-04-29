local M = {}

local function jump_to_range(bufnr, range)
  if not range then return end
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_set_current_buf(bufnr)
  end
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
end

--- Returns an action function that jumps to the named field of the resolved node.
function M.to_field(field)
  return function(result)
    local node = result.variant.node
    if not node then return end
    local target = node[field]
    if not target then return end
    jump_to_range(result.bufnr, target.range)
  end
end

return M
