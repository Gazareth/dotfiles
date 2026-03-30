local constants = require("configs.nui.treesitter.parsers.function.lib.constants")
local node_types = require("configs.nui.treesitter.lib.constants").node_types

local M = {}

-- Finds the parameter container node (e.g., parameters, parameter_list, formal_parameters) within a function node
function M.find_parameter_container(node)
  local named_count = node:named_child_count()
  for i = 0, named_count - 1 do
    local child = node:named_child(i)
    local child_type = child:type()
    if child_type == node_types.parameters
      or child_type == node_types.parameter_list
      or child_type == node_types.formal_parameters then
      return child
    end
  end

  return nil
end

-- Counts the number of parameters in a function node by looking for parameter nodes within the parameter container
function M.count_parameters(node)
  local params = M.find_parameter_container(node)
  if not params then
    return nil
  end

  local count = 0
  local named_count = params:named_child_count()

  for i = 0, named_count - 1 do
    local child = params:named_child(i)
    if constants.parameter_types[child:type()] then
      count = count + 1
    end
  end

  return count
end

return M