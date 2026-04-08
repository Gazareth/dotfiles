local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Node capabilities by kind
function M.by_node_kind(node_kind)
  return node_actions.get_node_action_ids(node_kind)
end

return M
