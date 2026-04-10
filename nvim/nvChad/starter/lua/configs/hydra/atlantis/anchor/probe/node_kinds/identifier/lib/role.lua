local treesitter_constants = require("configs.hydra.atlantis.anchor.probe.treesitter.constants")
local supported_nodes = treesitter_constants.supported_nodes
local roles = treesitter_constants.roles
local identifier_role_parent_types = treesitter_constants.identifier_role_parent_types

local FIELD_PARENT_TYPES = identifier_role_parent_types.field
local PARAMETER_PARENT_TYPES = identifier_role_parent_types.parameter
local DECLARATION_PARENT_TYPES = identifier_role_parent_types.binding

local M = {}

-- Classify identifier role from immediate and ancestor syntax context
function M.classify_identifier_role(node_info)
  if FIELD_PARENT_TYPES[node_info.parent_type] then
    return roles.field
  end

  if PARAMETER_PARENT_TYPES[node_info.parent_type] then
    return roles.parameter
  end

  if DECLARATION_PARENT_TYPES[node_info.parent_type] then
    return roles.binding
  end

  if FIELD_PARENT_TYPES[node_info.grandparent_type] then
    return roles.field
  end

  if PARAMETER_PARENT_TYPES[node_info.grandparent_type] then
    return roles.parameter
  end

  return roles.identifier
end

-- Build display label for classified identifier role
local function build_display_name(role)
  if role == roles.binding then
    return roles.identifier .. " " .. roles.binding
  end

  return role
end

-- Build normalized identifier parse payload for menu routing
function M.build_identifier_result(node_info, role)
  return {
    node_kind = supported_nodes.identifier,
    role = role,
    display_name = build_display_name(role),
    summary = {
      parent_type = node_info.parent_type,
      grandparent_type = node_info.grandparent_type,
    },
  }
end

return M
