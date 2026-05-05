local scoped = require("configs.hydra.atlantis-deprecated.lib.resolver")

local M = {}

local root_prefix = "configs.hydra.atlantis-deprecated.menu.components.action.labels"

function M.resolve(action_name, anchor_kind)
  return scoped.resolve(root_prefix, action_name, anchor_kind)
end

return M
