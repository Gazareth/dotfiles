local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Yank action behavior
function M.build(ctx)
  return lib.placeholder("Yank", lib.resolve_node_label(ctx))
end

return M
