local node_actions = require("configs.hydra.atlantis.registry.node_actions")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Rename function/method via LSP
function M.build_change_name_action()
  return node_actions.build(supported_nodes.fn, "change_name", {})
end

-- Show call hierarchy when available
function M.build_call_hierarchy_action()
  return node_actions.build(supported_nodes.fn, "view_call_hierarchy", {})
end

return M
