-- Build generic jump-lhs fallback for missing structured targets
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Build fallback jump-lhs closure
function M.build(_ctx)
  return lib.placeholder("Jump to", "left hand side")
end

return M
