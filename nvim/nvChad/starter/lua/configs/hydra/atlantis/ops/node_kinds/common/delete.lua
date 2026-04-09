local lib = require("configs.hydra.atlantis.ops.node_kinds.common.lib")

local M = {}

-- Delete action behavior
function M.build(ctx)
  return lib.visual_operator("Delete", "d", ctx)
end

return M
