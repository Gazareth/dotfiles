-- Build generic rename placeholder when node-specific rename is unavailable
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Build fallback rename closure for unsupported node kinds
function M.build(ctx)
  return lib.placeholder("Rename", lib.resolve_node_label(ctx))
end

return M
