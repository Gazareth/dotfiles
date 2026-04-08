local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Select action behavior
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
