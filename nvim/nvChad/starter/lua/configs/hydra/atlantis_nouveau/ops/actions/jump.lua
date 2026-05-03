local M = {}

local function jump_to_range(bufnr, range)
  if not range then return end
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_set_current_buf(bufnr)
  end
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
end

--- Returns an action function that jumps to the named field of the resolved node's state.
--- If the state field is a RawNode (has `.range`), jumps there directly.
--- If the state field is a scalar (e.g. a name string), falls back to the raw node's range.
function M.to_field(field)
  return function(result)
    local node = result.node and result.node.node
    if not node then return end
    local state = node.state
    if not state then return end
    local target = state[field]
    if type(target) == "table" and target.range then
      jump_to_range(result.bufnr, target.range)
    else
      -- field is a scalar (e.g. Assignment.name is a string) — jump to the node start
      jump_to_range(result.bufnr, node.raw and node.raw.range)
    end
  end
end

return M
