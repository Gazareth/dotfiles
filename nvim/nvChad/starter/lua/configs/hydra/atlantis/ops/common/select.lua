local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Select action behavior
function M.build(ctx)
  return lib.placeholder("Select", lib.resolve_node_label(ctx))
end

return M
