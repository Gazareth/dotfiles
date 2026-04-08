local common = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Change action passthrough
function M.build(ctx)
  return common.change(ctx)
end

return M
