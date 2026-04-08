local common = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Edit action passthrough
function M.build(ctx)
  return common.change(ctx)
end

return M
