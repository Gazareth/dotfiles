local metrics = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.node_kinds.function.lib.metrics")
local parameters = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.node_kinds.function.lib.parameters")
local node_common = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.common.node")

local M = {}

-- Find function name node before parameter container
local function find_function_name_node(function_node)
  local params = parameters.find_parameter_container(function_node)
  local named_children = node_common.list_named_children(function_node)
  local fallback_node = nil

  for _, child in ipairs(named_children) do
    if params and child:id() == params:id() then
      break
    end

    if not fallback_node then
      fallback_node = child
    end

    if child:type() == "identifier" then
      return child
    end
  end

  return fallback_node
end

-- Extract function name text before parameter container
function M.extract_function_name(function_node, bufnr)
  local params = parameters.find_parameter_container(function_node)
  local named_children = node_common.list_named_children(function_node)
  local fallback = ""

  for _, child in ipairs(named_children) do
    if params and child:id() == params:id() then
      break
    end

    local text = vim.trim(node_common.get_node_text(child, bufnr))
    if text ~= "" then
      if fallback == "" then
        fallback = text
      end

      if child:type() == "identifier" then
        return text
      end
    end
  end

  return fallback
end

-- Build rename/jump target for function name token
function M.build_function_name_target(node_info)
  local name_node = find_function_name_node(node_info.node)
  if not name_node then
    return nil
  end

  local name = vim.trim(node_common.get_node_text(name_node, node_info.bufnr))
  if name == "" then
    name = "function name"
  end

  return node_common.build_target(name_node, node_info.bufnr, "function name", "Function", name)
end

-- Build parameter container and parameter node jump targets
function M.build_parameter_targets(node_info)
  local parameter_nodes, parameter_container = parameters.list_parameters(node_info.node)
  local targets = {
    container = nil,
    parameters = {},
  }

  if parameter_container then
    targets.container = node_common.build_target(parameter_container, node_info.bufnr, "parameters", "Parameters", "list")
  end

  for index, node in ipairs(parameter_nodes or {}) do
    local parameter_name = vim.trim(node_common.get_node_text(node, node_info.bufnr))
    if parameter_name == "" then
      parameter_name = "parameter " .. tostring(index)
    end

    targets.parameters[index] = node_common.build_target(
      node,
      node_info.bufnr,
      "parameter " .. tostring(index),
      "Parameter",
      parameter_name
    )
  end

  return targets
end

-- Build jump targets for nested functions inside function body
function M.build_nested_function_targets(node_info)
  local targets = {}
  for _, node in ipairs(metrics.find_nested_functions(node_info.node)) do
    local name = M.extract_function_name(node, node_info.bufnr)
    if name == "" then
      name = "nested function"
    end

    targets[#targets + 1] = node_common.build_target(node, node_info.bufnr, name, "Function", name)
  end

  return targets
end

-- Build jump targets for assignment-like nodes in function body
function M.build_assignment_targets(node_info)
  local targets = {}
  local all_assignments = {}

  vim.list_extend(all_assignments, metrics.find_assignments(node_info.node))
  vim.list_extend(all_assignments, metrics.find_table_assignments(node_info.node))

  for index, node in ipairs(all_assignments) do
    local assignment_name = vim.trim(node_common.get_node_text(node, node_info.bufnr))
    if assignment_name == "" then
      assignment_name = "assignment " .. tostring(index)
    end

    targets[index] = node_common.build_target(
      node,
      node_info.bufnr,
      "assignment " .. tostring(index),
      "Assignment",
      assignment_name
    )
  end

  return targets
end

return M

