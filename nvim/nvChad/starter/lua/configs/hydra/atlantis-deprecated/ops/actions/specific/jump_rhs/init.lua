-- Build generic jump-rhs fallback for missing structured targets
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Build fallback jump-rhs closure
function M.build(_ctx)
  return lib.placeholder("Jump to", "right hand side")
end

return M
