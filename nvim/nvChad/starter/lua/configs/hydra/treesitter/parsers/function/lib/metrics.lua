local constants = require("configs.hydra.treesitter.parsers.function.lib.constants")
local parameters = require("configs.hydra.treesitter.parsers.function.lib.parameters")

local M = {}
local call_types = {
  call = true,
  call_expression = true,
  function_call = true,
}

-- Visit a node and all of its descendants.
local function walk(node, fn)
  if not node then
    return
  end

  fn(node)

  local child_count = node:named_child_count()
  for i = 0, child_count - 1 do
    walk(node:named_child(i), fn)
  end
end

-- Count descendants that match a given test.
function M.count_descendants(node, predicate)
  local count = 0
  walk(node, function(current)
    if current ~= node and predicate(current) then
      count = count + 1
    end
  end)
  return count
end

-- Collect descendants that match a given test.
function M.collect_descendants(node, predicate)
  local list = {}
  walk(node, function(current)
    if current ~= node and predicate(current) then
      list[#list + 1] = current
    end
  end)
  return list
end

-- Count nested functions inside the current function.
local function count_nested_functions(node)
  return M.count_descendants(node, function(current)
    return constants.function_like_types[current:type()] == true
  end)
end

-- Collect nested function nodes inside the current function.
function M.find_nested_functions(node)
  return M.collect_descendants(node, function(current)
    return constants.function_like_types[current:type()] == true
  end)
end

-- Count assignment nodes inside the current function.
local function count_assignments(node)
  return M.count_descendants(node, function(current)
    return constants.assignment_types[current:type()] == true
  end)
end

-- Collect assignment nodes inside the current function.
function M.find_assignments(node)
  return M.collect_descendants(node, function(current)
    return constants.assignment_types[current:type()] == true
  end)
end

-- Count table field assignments inside the current function.
local function count_table_assignments(node)
  return M.count_descendants(node, function(current)
    return constants.table_assignment_types[current:type()] == true
  end)
end

-- Collect table field assignment nodes inside the current function.
function M.find_table_assignments(node)
  return M.collect_descendants(node, function(current)
    return constants.table_assignment_types[current:type()] == true
  end)
end

-- Count calls made within the current function body.
local function count_calls(node)
  return M.count_descendants(node, function(current)
    return call_types[current:type()] == true
  end)
end

-- Collect call expressions within the current function body.
function M.find_calls(node)
  return M.collect_descendants(node, function(current)
    return call_types[current:type()] == true
  end)
end

-- Build the metrics table for a parsed function.
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
