local M = {}

local KEYS = { "1","2","3","4","5","6","7","8","9",
               "a","c","e","f","g","o","q","s","t","w","x","z" }

local function jump_to_item(bufnr, item)
  local range = item.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open(
      bufnr, item.target_mode,
      item.node_type, range.start_row, range.start_col
    )
  end)
end

function M.build(result)
  local items = result.outline
  if not items or #items == 0 then return nil end

  local rows = {}
  for i, item in ipairs(items) do
    rows[#rows + 1] = {
      key    = KEYS[i],
      label  = item.label,
      action = function() jump_to_item(result.bufnr, item) end,
    }
  end

  return { title = "Contents", items = rows }
end

return M
