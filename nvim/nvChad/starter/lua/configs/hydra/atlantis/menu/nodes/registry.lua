local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local capability = require("configs.hydra.atlantis.menu.nodes.capability")

local M = {}

-- Node-kind to menu-spec builder mapping
M.spec_builders = {
  [supported_nodes.generic] = capability.build,
  [supported_nodes.identifier] = capability.build,
  [supported_nodes.assignment] = capability.build,
  [supported_nodes.fn] = capability.build,
  [supported_nodes.parameter] = capability.build,
  [supported_nodes.body] = capability.build,
  [supported_nodes.return_stmt] = capability.build,
}

-- Resolve menu-spec builder for parsed node kind
function M.get_builder(node_kind)
  return M.spec_builders[node_kind]
end

-- Return default capability-based menu-spec builder
function M.get_generic_builder()
  return capability.build
end

return M
