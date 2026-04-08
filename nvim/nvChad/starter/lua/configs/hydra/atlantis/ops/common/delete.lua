local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Delete action behavior
function M.build(ctx)
  return lib.visual_operator("Delete", "d", ctx)
end

return M
