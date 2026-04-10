-- Build delete action from resolved node range
local lib = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Build delete closure using visual operator helper
function M.build(ctx)
  return lib.visual_operator("Delete", "d", ctx)
end

return M
