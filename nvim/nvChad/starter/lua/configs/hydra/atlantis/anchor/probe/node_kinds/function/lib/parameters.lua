local constants = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.constants")
local treesitter_constants = require("configs.hydra.atlantis.anchor.probe.treesitter.constants")
local node_common = require("configs.hydra.atlantis.anchor.probe.common.node")
local parameter_container_types = treesitter_constants.parameter_container_types

local M = {}

-- Count named children matching provided predicate
local function count_named_children(node, predicate)
  local count = 0
  for _, child in ipairs(node_common.list_named_children(node)) do
    if predicate(child) then
      count = count + 1
    end
  end

  return count
end

-- Find parameter container node for function-like node
function M.find_parameter_container(node)
  for _, child in ipairs(node_common.list_named_children(node)) do
    if parameter_container_types[child:type()] then
      return child
    end
  end

  return nil
end

-- Count parameter nodes inside function parameter container
function M.count_parameters(node)
  local params = M.find_parameter_container(node)
  if not params then
    return nil
  end

  return count_named_children(params, function(child)
    return constants.parameter_types[child:type()] == true
  end)
end

-- List parameter nodes with fallback for uncommon grammars
function M.list_parameters(node)
  local params = M.find_parameter_container(node)
  if not params then
    return nil
  end

  local list = {}
  local named_children = node_common.list_named_children(params)

  for _, child in ipairs(named_children) do
    if constants.parameter_types[child:type()] == true then
      list[#list + 1] = child
    end
  end

  -- Fallback to first named child when grammar omits parameter node type
  if #list == 0 and #named_children > 0 then
    local first_named = named_children[1]
    if first_named then
      list[#list + 1] = first_named
    end
  end

  return list, params
end

return M
