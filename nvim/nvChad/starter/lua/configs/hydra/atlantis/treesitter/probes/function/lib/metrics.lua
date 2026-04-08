local constants = require("configs.hydra.atlantis.treesitter.probes.function.lib.constants")
local parameters = require("configs.hydra.atlantis.treesitter.probes.function.lib.parameters")

local M = {}
local call_types = {
  call = true,
  call_expression = true,
  function_call = true,
}

-- Recursive node walk
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

-- Matching descendant count
function M.count_descendants(node, predicate)
  local count = 0
  walk(node, function(current)
    if current ~= node and predicate(current) then
      count = count + 1
    end
  end)
  return count
end

-- Matching descendant list
function M.collect_descendants(node, predicate)
  local list = {}
  walk(node, function(current)
    if current ~= node and predicate(current) then
      list[#list + 1] = current
    end
  end)
  return list
end

-- Nested function count
local function count_nested_functions(node)
  return M.count_descendants(node, function(current)
    return constants.function_like_types[current:type()] == true
  end)
end

-- Nested function list
function M.find_nested_functions(node)
  return M.collect_descendants(node, function(current)
    return constants.function_like_types[current:type()] == true
  end)
end

-- Assignment count
local function count_assignments(node)
  return M.count_descendants(node, function(current)
    return constants.assignment_types[current:type()] == true
  end)
end

-- Assignment list
function M.find_assignments(node)
  return M.collect_descendants(node, function(current)
    return constants.assignment_types[current:type()] == true
  end)
end

-- Table assignment count
local function count_table_assignments(node)
  return M.count_descendants(node, function(current)
    return constants.table_assignment_types[current:type()] == true
  end)
end

-- Table assignment list
function M.find_table_assignments(node)
  return M.collect_descendants(node, function(current)
    return constants.table_assignment_types[current:type()] == true
  end)
end

-- Call count
local function count_calls(node)
  return M.count_descendants(node, function(current)
    return call_types[current:type()] == true
  end)
end

-- Call list
function M.find_calls(node)
  return M.collect_descendants(node, function(current)
    return call_types[current:type()] == true
  end)
end

-- Function metrics
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
