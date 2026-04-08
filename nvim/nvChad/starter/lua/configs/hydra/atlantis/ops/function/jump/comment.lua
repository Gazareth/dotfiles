local common_actions = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Comment jump placeholder
function M.build(_ctx)
  return common_actions.placeholder("Jump to", "comment")
end

return M
