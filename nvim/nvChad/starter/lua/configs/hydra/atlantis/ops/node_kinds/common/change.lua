local lib = require("configs.hydra.atlantis.ops.node_kinds.common.lib")

local M = {}

-- Change action behavior
function M.build(ctx)
  return lib.visual_operator("Change", "c", ctx)
end

return M
