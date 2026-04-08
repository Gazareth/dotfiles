local common = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Swap action passthrough
function M.build(ctx)
  return common.swap(ctx)
end

return M
