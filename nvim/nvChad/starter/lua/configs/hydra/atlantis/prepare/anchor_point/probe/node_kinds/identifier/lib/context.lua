local treesitter_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants")
local roles = treesitter_constants.roles
local function_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.constants")
local function_parameters = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.parameters")
local parse_function = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function").parse_function
local build_node_info = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")

local M = {}

-- Check whether identifier belongs to function name region
local function is_function_name_identifier(node, function_ancestor)
  local params = function_parameters.find_parameter_container(function_ancestor)
  local child_count = function_ancestor:named_child_count()

  for i = 0, child_count - 1 do
    local child = function_ancestor:named_child(i)
    if params and child:id() == params:id() then
      break
    end

    if node_common.is_descendant_of(node, child) then
      return true
    end
  end

  return false
end

-- Find enclosing function where identifier is part of function name
local function find_function_context_ancestor(node)
  return node_common.find_ancestor_of_types(node, function_constants.function_like_types, {
    include_self = false,
    predicate = function(current)
      return is_function_name_identifier(node, current)
    end,
  })
end

-- Reuse parsed function payload as identifier context payload
local function build_function_identifier_result(function_node_info, parsed_function)
  local function_role = parsed_function.role or roles.fn
  parsed_function.node_type = function_node_info.node_type
  parsed_function.text = function_node_info.text
  -- Force semantic mapping to use function node context
  parsed_function.semantic_node_info = function_node_info
  parsed_function.role = function_role .. " " .. roles.identifier
  parsed_function.display_name = parsed_function.role
  return parsed_function
end

-- Parse identifier as function-name context when applicable
function M.try_parse_identifier_function_context(node_info)
  local function_ancestor = find_function_context_ancestor(node_info.node)
  if not function_ancestor then
    return nil
  end

  local function_node_info = build_node_info({
    bufnr = node_info.bufnr,
    node = function_ancestor,
  })

  if not function_node_info then
    return nil
  end

  local ok, parsed = pcall(parse_function, function_node_info)
  if not ok or type(parsed) ~= "table" then
    return nil
  end

  return build_function_identifier_result(function_node_info, parsed)
end

return M
