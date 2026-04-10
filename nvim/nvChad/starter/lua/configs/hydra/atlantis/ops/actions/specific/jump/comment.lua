-- Build function jump-to-comment placeholder until comment-target parsing exists
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Build jump-to-comment placeholder closure
function M.build(_ctx)
  return common_actions.placeholder("Jump to", "comment")
end

return M
