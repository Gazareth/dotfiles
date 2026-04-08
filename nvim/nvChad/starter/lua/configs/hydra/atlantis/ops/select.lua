local common = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Select action passthrough
function M.build(ctx)
  return common.select(ctx)
end

return M
