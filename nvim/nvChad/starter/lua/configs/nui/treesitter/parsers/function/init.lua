local lib = require("configs.nui.treesitter.parsers.function.lib")
local treesitter_constants = require("configs.nui.treesitter.lib.constants")
local supported_nodes = treesitter_constants.supported_nodes

local M = {}

-- Parse a function node into its label and metrics.
function M.parse_function(node_info)
  local method_kind = lib.is_function_or_method(node_info)

  return {
    node_kind = supported_nodes["function"],
    role = method_kind,
    display_name = method_kind,
    metrics = lib.build_function_metrics(node_info),
  }
end

return M