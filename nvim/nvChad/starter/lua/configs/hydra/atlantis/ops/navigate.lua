local common = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Navigate action passthrough
function M.build(ctx)
  return common.jump(ctx)
end

return M
