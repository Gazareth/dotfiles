local common_actions = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Return jump placeholder
function M.build(_ctx)
  return common_actions.placeholder("Jump to", "return")
end

return M
