local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local generic = require("configs.hydra.atlantis.menu.nodes.generic")
local identifier = require("configs.hydra.atlantis.menu.nodes.identifier")
local assignment = require("configs.hydra.atlantis.menu.nodes.assignment")
local function_spec = require("configs.hydra.atlantis.menu.nodes.function")
local parameter_spec = require("configs.hydra.atlantis.menu.nodes.function.parameter")
local body_spec = require("configs.hydra.atlantis.menu.nodes.function.body")
local return_spec = require("configs.hydra.atlantis.menu.nodes.function.return")

local M = {}

-- Node builder registry
M.spec_builders = {
  [supported_nodes.identifier] = identifier.build,
  [supported_nodes.assignment] = assignment.build,
  [supported_nodes.fn] = function_spec.build,
  [supported_nodes.parameter] = parameter_spec.build,
  [supported_nodes.body] = body_spec.build,
  [supported_nodes.return_stmt] = return_spec.build,
}

-- Node builder resolver
function M.get_builder(node_kind)
  return M.spec_builders[node_kind]
end

-- Generic builder accessor
function M.get_generic_builder()
  return generic.build
end

return M
