-- Icon and label lookup tables for node kind badges in menu titles
local node_kinds_const = require("configs.hydra.atlantis.anchor.registry.kinds").node_kinds

local M = {}

-- Fallback icon by semantic kind for title badges
local kind_icons = {
  [node_kinds_const.declaration]   = "ƒ",
  [node_kinds_const.comment]       = "🗨",
  [node_kinds_const.assignment]    = "◈",
  [node_kinds_const.control_frame] = "⊡",
  [node_kinds_const.call]          = "⊛",
  [node_kinds_const.identifier]    = "·",
  [node_kinds_const.string]        = "❝",
  [node_kinds_const.collection]    = "⊏",
  [node_kinds_const.property]      = "⊕",
  [node_kinds_const.statement]     = "·",
}

-- Fallback label by semantic kind for title badges
local kind_labels = {
  [node_kinds_const.declaration]   = "Function",
  [node_kinds_const.comment]       = "Comment",
  [node_kinds_const.assignment]    = "Assignment",
  [node_kinds_const.control_frame] = "Block",
  [node_kinds_const.call]          = "Call",
  [node_kinds_const.identifier]    = "Identifier",
  [node_kinds_const.string]        = "String",
  [node_kinds_const.collection]    = "Collection",
  [node_kinds_const.property]      = "Property",
  [node_kinds_const.statement]     = "Statement",
}

-- Node-type label overrides for clearer titles
local type_labels = {
  for_statement = "For loop",
  for_in_statement = "For loop",
  if_statement = "If",
  while_statement = "While loop",
  repeat_statement = "Repeat",
  function_call = "Call",
  method_definition = "Method",
  parameter = "Parameter",
  parameter_declaration = "Parameter",
  typed_parameter = "Parameter",
  parameters = "Parameters",
  parameter_list = "Parameters",
  formal_parameters = "Parameters",
}

-- Node-type icon overrides for clearer titles
local type_icons = {
  for_statement = "➰",
  for_in_statement = "➰",
  if_statement = "⁇",
  while_statement = "↺",
  repeat_statement = "↺",
  method_definition = "·",
  parameter = "󰆧",
  parameter_declaration = "󰆧",
  typed_parameter = "󰆧",
  parameters = "󰆧",
  parameter_list = "󰆧",
  formal_parameters = "󰆧",
}

-- Resolve title label from node-type override then semantic fallback
function M.resolve_label(semantic_kind, node_type)
  return type_labels[node_type] or kind_labels[semantic_kind] or "Node"
end

-- Resolve title icon from node-type override then semantic fallback
function M.resolve_icon(semantic_kind, node_type)
  return type_icons[node_type] or kind_icons[semantic_kind] or "�"
end

return M
