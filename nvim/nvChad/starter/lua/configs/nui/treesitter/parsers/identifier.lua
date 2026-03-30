local M = {}
local node_types = require("configs.nui.treesitter.lib.constants").node_types
local supported_nodes = require("configs.nui.treesitter.lib.constants").supported_nodes

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

function M.parse_identifier(node_info)
  local role = "identifier"

  if FIELD_PARENT_TYPES[node_info.parent_type] then
    role = "field"
  elseif PARAMETER_PARENT_TYPES[node_info.parent_type] then
    role = "parameter"
  elseif DECLARATION_PARENT_TYPES[node_info.parent_type] then
    role = "binding"
  elseif FIELD_PARENT_TYPES[node_info.grandparent_type] then
    role = "field"
  elseif PARAMETER_PARENT_TYPES[node_info.grandparent_type] then
    role = "parameter"
  end

  local display_name = role
  if role == "binding" then
    display_name = "identifier binding"
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
