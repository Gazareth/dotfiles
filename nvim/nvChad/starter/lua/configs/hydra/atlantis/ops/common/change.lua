local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Change action behavior
function M.build(ctx)
  return lib.placeholder("Change", lib.resolve_node_label(ctx))
end

return M
