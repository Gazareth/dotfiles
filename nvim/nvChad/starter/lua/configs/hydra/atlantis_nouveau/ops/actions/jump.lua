local M = {}

local function jump_to_range(range)
  if not range then return end
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
      if target.target_mode then
        -- It's a NavigationTarget — jump and reopen Atlantis in the correct mode
        jump_to_range(target.range)
        vim.schedule(function()
          require("configs.hydra.atlantis_nouveau").open(
            result.bufnr, target.target_mode,
            target.node_type, target.range.start_row, target.range.start_col
          )
        end)
      else
        jump_to_range(target.range)
      end
    else
      -- field is a scalar (e.g. Assignment.name is a string) — jump to the node start
      jump_to_range(node.raw and node.raw.range)
    end
  end
end

return M
