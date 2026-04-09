local treesitter_constants = require("configs.hydra.atlantis.treesitter.common.constants")
local function_constants = require("configs.hydra.atlantis.treesitter.probes.function.lib.constants")
local function_parameters = require("configs.hydra.atlantis.treesitter.probes.function.lib.parameters")
local node_common = require("configs.hydra.atlantis.treesitter.probes.common.node")

local supported_nodes = treesitter_constants.supported_nodes
local roles = treesitter_constants.roles
local parameter_container_types = treesitter_constants.parameter_container_types

local M = {}

-- Find nearest function-like ancestor for parameter context
local function find_function_ancestor(node)
  return node_common.find_ancestor_of_types(node, function_constants.function_like_types, {
    include_self = true,
  })
end

-- Resolve parameter index containing current cursor node
local function resolve_current_parameter_index(cursor_node, parameter_nodes)
  for index, parameter_node in ipairs(parameter_nodes or {}) do
    if node_common.is_descendant_of(cursor_node, parameter_node) then
      return index
    end
  end

  if #parameter_nodes > 0 then
    return 1
  end

  return nil
end

-- Build parameter context from current node location
local function build_parameter_context(node)
  local function_node = find_function_ancestor(node)
  if not function_node then
    return nil
  end

  local parameter_nodes, parameter_container = function_parameters.list_parameters(function_node)
  if not parameter_container then
    return nil
  end

  if #parameter_nodes == 0 and parameter_container_types[node:type()] ~= true then
    return nil
  end

  local current_index = resolve_current_parameter_index(node, parameter_nodes)

  return {
    function_node = function_node,
    parameter_nodes = parameter_nodes or {},
    parameter_container = parameter_container,
    current_index = current_index,
  }
end

-- Build parameter parse payload with sibling targets and metrics
function M.parse_parameter(node_info)
  local context = build_parameter_context(node_info.node)
  if not context then
    return {
      node_kind = supported_nodes.parameter,
      role = roles.parameter,
      display_name = roles.parameter,
      parameter_count = 0,
      parameter_index = nil,
      targets = {
        parameter_container = nil,
        parameters = {},
        current_parameter = nil,
        previous_parameter = nil,
        next_parameter = nil,
      },
      parameter_nodes = {},
      parameter_container_node = nil,
      summary = {},
    }
  end

  local parameter_nodes = context.parameter_nodes
  local parameter_targets = {}

  for index, node in ipairs(parameter_nodes) do
    local parameter_name = vim.trim(node_common.get_node_text(node, node_info.bufnr))
    if parameter_name == "" then
      parameter_name = "parameter " .. tostring(index)
    end

    parameter_targets[index] = node_common.build_target(
      node,
      node_info.bufnr,
      "parameter " .. tostring(index),
      "Parameter",
      parameter_name
    )
  end

  local current_index = context.current_index

  return {
    node_kind = supported_nodes.parameter,
    role = roles.parameter,
    display_name = roles.parameter,
    parameter_count = #parameter_nodes,
    parameter_index = current_index,
    targets = {
      parameter_container = node_common.build_target(
        context.parameter_container,
        node_info.bufnr,
        "parameters",
        "Parameters",
        "list"
      ),
      parameters = parameter_targets,
      current_parameter = current_index and parameter_targets[current_index] or nil,
      previous_parameter = current_index and parameter_targets[current_index - 1] or nil,
      next_parameter = current_index and parameter_targets[current_index + 1] or nil,
    },
    parameter_nodes = parameter_nodes,
    parameter_container_node = context.parameter_container,
    summary = {
      parameter_count = #parameter_nodes,
    },
  }
end

return M