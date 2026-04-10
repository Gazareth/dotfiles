-- Build function jump-to-return placeholder until return-target parsing exists
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Build jump-to-return placeholder closure
function M.build(_ctx)
  return common_actions.placeholder("Jump to", "return")
end

return M
