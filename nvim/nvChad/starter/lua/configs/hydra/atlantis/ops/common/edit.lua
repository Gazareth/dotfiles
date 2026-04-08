local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Edit action behavior
function M.build(ctx)
  return lib.placeholder("Edit", lib.resolve_node_label(ctx))
end

return M
