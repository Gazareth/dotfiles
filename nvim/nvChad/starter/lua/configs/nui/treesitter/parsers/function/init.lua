local lib = require("configs.nui.treesitter.parsers.function.lib")
local supported_nodes = require("configs.nui.treesitter.lib.constants").supported_nodes

local M = {}

function M.parse_function(node_info)
  local line_span = node_info.end_row - node_info.start_row + 1
  local method_kind = lib.detect_method_kind(node_info)

  local nested_function_count = lib.count_descendants(node_info.node, function(current)
    return lib.function_like_types[current:type()] == true
  end)

  local assignment_count = lib.count_descendants(node_info.node, function(current)
    return lib.assignment_types[current:type()] == true
  end)

  local table_assignment_count = lib.count_descendants(node_info.node, function(current)
    return lib.table_assignment_types[current:type()] == true
  end)

  return {
    node_kind = supported_nodes["function"],
    role = method_kind,
    display_name = method_kind,
    metrics = {
      parameter_count = lib.count_parameters(node_info.node),
      line_span = line_span,
      nested_function_count = nested_function_count,
      assignment_count = assignment_count,
      table_assignment_count = table_assignment_count,
    },
  }
end

return M