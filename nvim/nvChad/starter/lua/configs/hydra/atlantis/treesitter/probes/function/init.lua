local lib = require("configs.hydra.atlantis.treesitter.probes.function.lib")
local targets = require("configs.hydra.atlantis.treesitter.probes.function.lib.targets")
local treesitter_constants = require("configs.hydra.atlantis.treesitter.common.constants")
local supported_nodes = treesitter_constants.supported_nodes

local M = {}

-- Function parse result
function M.parse_function(node_info)
  local method_kind = lib.is_function_or_method(node_info)
  local function_name = targets.extract_function_name(node_info.node, node_info.bufnr)
  if function_name == "" then
    function_name = "anonymous"
  end

  local parameter_targets = targets.build_parameter_targets(node_info)
  local nested_function_targets = targets.build_nested_function_targets(node_info)
  local assignment_targets = targets.build_assignment_targets(node_info)

  return {
    node_kind = supported_nodes.fn,
    role = method_kind,
    display_name = method_kind,
    function_name = function_name,
    metrics = lib.build_function_metrics(node_info),
    targets = {
      parameter_container = parameter_targets.container,
      parameters = parameter_targets.parameters,
      nested_functions = nested_function_targets,
      assignments = assignment_targets,
    },
  }
end

return M
