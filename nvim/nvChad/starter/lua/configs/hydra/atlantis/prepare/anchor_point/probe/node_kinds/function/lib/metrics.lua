local constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.constants")
local parameters = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.parameters")
local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")

local M = {}
local call_types = {
  call = true,
  call_expression = true,
  function_call = true,
}

-- Walk named descendant tree depth-first
local function walk(node, fn)
  if not node then
    return
  end

  fn(node)

  for _, child in ipairs(node_common.list_named_children(node)) do
    walk(child, fn)
  end
end

-- Count descendants matching predicate
function M.count_descendants(node, predicate)
  local count = 0
  walk(node, function(current)
    if current ~= node and predicate(current) then
      count = count + 1
    end
  end)
  return count
end

-- Collect descendants matching predicate
function M.collect_descendants(node, predicate)
  local list = {}
  walk(node, function(current)
    if current ~= node and predicate(current) then
      list[#list + 1] = current
    end
  end)
  return list
end

-- Count nested function-like descendants
local function count_nested_functions(node)
  return M.count_descendants(node, function(current)
    return constants.function_like_types[current:type()] == true
  end)
end

-- Collect nested function-like descendants
function M.find_nested_functions(node)
  return M.collect_descendants(node, function(current)
    return constants.function_like_types[current:type()] == true
  end)
end

-- Count assignment-like descendants
local function count_assignments(node)
  return M.count_descendants(node, function(current)
    return constants.assignment_types[current:type()] == true
  end)
end

-- Collect assignment-like descendants
function M.find_assignments(node)
  return M.collect_descendants(node, function(current)
    return constants.assignment_types[current:type()] == true
  end)
end

-- Count table assignment descendants
local function count_table_assignments(node)
  return M.count_descendants(node, function(current)
    return constants.table_assignment_types[current:type()] == true
  end)
end

-- Collect table assignment descendants
function M.find_table_assignments(node)
  return M.collect_descendants(node, function(current)
    return constants.table_assignment_types[current:type()] == true
  end)
end

-- Count call-like descendants
local function count_calls(node)
  return M.count_descendants(node, function(current)
    return call_types[current:type()] == true
  end)
end

-- Collect call-like descendants
function M.find_calls(node)
  return M.collect_descendants(node, function(current)
    return call_types[current:type()] == true
  end)
end

-- Build function metrics used by menu titles and summaries
function M.build_function_metrics(node_info)
  return {
    parameter_count = parameters.count_parameters(node_info.node),
    line_span = node_info.end_row - node_info.start_row + 1,
    nested_function_count = count_nested_functions(node_info.node),
    assignment_count = count_assignments(node_info.node),
    table_assignment_count = count_table_assignments(node_info.node),
    called_count = count_calls(node_info.node),
  }
end

return M
