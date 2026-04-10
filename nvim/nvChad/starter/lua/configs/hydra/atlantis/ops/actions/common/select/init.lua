-- Build select action from resolved node range
local lib = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Build select closure with range availability guard
function M.build(ctx)
  return function()
    local range = lib.resolve_range(ctx)
    if not range or not lib.select_range(range) then
      vim.notify("Select " .. lib.resolve_node_label(ctx) .. " is not available.", vim.log.levels.INFO)
      return
    end
  end
end

return M
