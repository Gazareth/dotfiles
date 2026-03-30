local M = {}
local treesitter_constants = require("configs.nui.treesitter.lib.constants")
local node_types = treesitter_constants.node_types
local supported_nodes = treesitter_constants.supported_nodes
local roles = treesitter_constants.roles
local function_constants = require("configs.nui.treesitter.parsers.function.lib.constants")
local function_lib = require("configs.nui.treesitter.parsers.function.lib")
local parse_function = require("configs.nui.treesitter.parsers.function").parse_function
local build_node_info = require("configs.nui.treesitter.lib").build_node_info

local FIELD_PARENT_TYPES = {
  [node_types.field] = true,
  [node_types.pair] = true,
  [node_types.property] = true,
  [node_types.property_identifier] = true,
  [node_types.object] = true,
}

local PARAMETER_PARENT_TYPES = {
  [node_types.parameter] = true,
  [node_types.parameters] = true,
  [node_types.parameter_list] = true,
  [node_types.formal_parameters] = true,
  [node_types.arguments] = true,
}

local DECLARATION_PARENT_TYPES = {
  [node_types.variable_declaration] = true,
  [node_types.local_declaration] = true,
  [node_types.assignment_statement] = true,
  [node_types.assignment_expression] = true,
}

local function is_descendant_of(node, ancestor)
  local current = node
  while current do
    if current:id() == ancestor:id() then
      return true
    end

    current = current:parent()
  end

  return false
end

local function is_function_name_identifier(node, function_ancestor)
  local params = function_lib.find_parameter_container(function_ancestor)
  local child_count = function_ancestor:named_child_count()

  for i = 0, child_count - 1 do
    local child = function_ancestor:named_child(i)
    if params and child:id() == params:id() then
      break
    end

    if is_descendant_of(node, child) then
      return true
    end
  end

  return false
end

local function find_function_context_ancestor(node)
  local current = node and node:parent() or nil
  while current do
    if function_constants.function_like_types[current:type()]
      and is_function_name_identifier(node, current) then
      return current
    end

    current = current:parent()
  end

  return nil
end

function M.parse_identifier(node_info)
    -- First, check if this identifier is part of a function/method definition or declaration by looking for an ancestor node that represents a function-like construct. If such an ancestor exists, we can parse it as a function and use that information to provide more context about the identifier.
  local function_ancestor = find_function_context_ancestor(node_info.node)
  if function_ancestor then
    local function_node_info = build_node_info({
      bufnr = node_info.bufnr,
      node = function_ancestor,
    })

    if function_node_info then
      local ok, parsed = pcall(parse_function, function_node_info)
      if ok and type(parsed) == "table" then
        local function_role = parsed.role or roles["function"]
        parsed.node_type = function_node_info.node_type
        parsed.text = function_node_info.text
        parsed.role = function_role .. " " .. roles.identifier
        parsed.display_name = parsed.role
        return parsed
      end
    end
  end

  local role = roles.identifier

  if FIELD_PARENT_TYPES[node_info.parent_type] then
    role = roles.field
  elseif PARAMETER_PARENT_TYPES[node_info.parent_type] then
    role = roles.parameter
  elseif DECLARATION_PARENT_TYPES[node_info.parent_type] then
    role = roles.binding
  elseif FIELD_PARENT_TYPES[node_info.grandparent_type] then
    role = roles.field
  elseif PARAMETER_PARENT_TYPES[node_info.grandparent_type] then
    role = roles.parameter
  end

  local display_name = role
  if role == roles.binding then
    display_name = roles.identifier .. " " .. roles.binding
  end

  return {
    node_kind = supported_nodes.identifier,
    role = role,
    display_name = display_name,
    summary = {
      parent_type = node_info.parent_type,
      grandparent_type = node_info.grandparent_type,
    },
  }
end

return M
