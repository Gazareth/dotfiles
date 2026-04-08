local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Change action behavior
function M.build(ctx)
  return lib.visual_operator("Change", "c", ctx)
end

return M
