-- Build rename fallback when no node-specific rename override exists
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Build fallback rename closure for unresolved target kinds
function M.build(ctx)
  return lib.placeholder("Rename", lib.resolve_node_label(ctx))
end

return M
