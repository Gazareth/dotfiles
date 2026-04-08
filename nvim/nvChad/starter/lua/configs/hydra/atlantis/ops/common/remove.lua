local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Remove action behavior
function M.build(ctx)
  return lib.placeholder("Remove", lib.resolve_node_label(ctx))
end

return M
