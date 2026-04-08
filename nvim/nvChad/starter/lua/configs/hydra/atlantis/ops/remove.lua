local common = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Remove action passthrough
function M.build(ctx)
  return common.delete(ctx)
end

return M
