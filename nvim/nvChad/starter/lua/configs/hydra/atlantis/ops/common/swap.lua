local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Swap action behavior
function M.build(ctx)
  return lib.placeholder("Swap", lib.resolve_node_label(ctx))
end

return M
