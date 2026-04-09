local constants = require("configs.hydra.atlantis.treesitter.probes.function.lib.constants")
local treesitter_constants = require("configs.hydra.atlantis.treesitter.common.constants")
local parameter_container_types = treesitter_constants.parameter_container_types

local M = {}

-- Matching child count
local function count_named_children(node, predicate)
  local count = 0
  local named_count = node:named_child_count()

  for i = 0, named_count - 1 do
    local child = node:named_child(i)
    if predicate(child) then
      count = count + 1
    end
  end

  return count
end

-- Parameter container lookup
function M.find_parameter_container(node)
  local named_count = node:named_child_count()
  for i = 0, named_count - 1 do
    local child = node:named_child(i)
    if parameter_container_types[child:type()] then
      return child
    end
  end

  return nil
end

-- Parameter count
function M.count_parameters(node)
  local params = M.find_parameter_container(node)
  if not params then
    return nil
  end

  return count_named_children(params, function(child)
    return constants.parameter_types[child:type()] == true
  end)
end

-- Parameter node list
function M.list_parameters(node)
  local params = M.find_parameter_container(node)
  if not params then
    return nil
  end

  local list = {}
  local named_count = params:named_child_count()

  for i = 0, named_count - 1 do
    local child = params:named_child(i)
    if constants.parameter_types[child:type()] == true then
      list[#list + 1] = child
    end
  end

  -- Fallback first named child
  if #list == 0 and named_count > 0 then
    local first_named = params:named_child(0)
    if first_named then
      list[#list + 1] = first_named
    end
  end

  return list, params
end

return M
