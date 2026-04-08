local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Delete action behavior
function M.build(ctx)
  return lib.placeholder("Delete", lib.resolve_node_label(ctx))
end

return M
