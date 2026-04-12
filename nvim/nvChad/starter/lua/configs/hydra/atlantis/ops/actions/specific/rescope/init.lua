local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

function M.build(ctx)
  return common_actions.placeholder("Re-scope", "unsupported for this anchor")
end

return M
