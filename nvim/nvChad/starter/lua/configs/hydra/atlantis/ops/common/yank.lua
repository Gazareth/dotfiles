local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Yank action behavior
function M.build(ctx)
  return lib.visual_operator("Yank", "y", ctx)
end

return M
