-- Build change action from resolved node range
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Build change closure using visual operator helper
function M.build(ctx)
  return lib.visual_operator("Change", "c", ctx)
end

return M
