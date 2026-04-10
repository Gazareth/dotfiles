-- Build yank action from resolved node range
local lib = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Build yank closure using visual operator helper
function M.build(ctx)
  return lib.visual_operator("Yank", "y", ctx)
end

return M
