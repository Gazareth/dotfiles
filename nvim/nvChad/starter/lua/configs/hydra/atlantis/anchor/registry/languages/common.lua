local M = {}
local atlantis_constants = require("configs.hydra.atlantis.anchor.registry.kinds")
local node_tiers = atlantis_constants.node_tiers
local node_kinds = atlantis_constants.node_kinds

-- Common node mappings
M.mappings = {
  function_declaration = {
    node_tier = node_tiers.settlement,
    node_kind = node_kinds.declaration,
    actionable = true,
  },
  function_definition = {
    node_tier = node_tiers.settlement,
    node_kind = node_kinds.declaration,
    actionable = true,
  },
  parameters = {
    node_tier = node_tiers.grove,
    node_kind = node_kinds.collection,
    actionable = true,
  },
  parameter_list = {
    node_tier = node_tiers.grove,
    node_kind = node_kinds.collection,
    actionable = true,
  },
  formal_parameters = {
    node_tier = node_tiers.grove,
    node_kind = node_kinds.collection,
    actionable = true,
  },
  arguments = {
    node_tier = node_tiers.grove,
    node_kind = node_kinds.collection,
    actionable = true,
  },
  if_statement = {
    node_tier = node_tiers.cluster,
    node_kind = node_kinds.control_frame,
    actionable = true,
  },
  for_statement = {
    node_tier = node_tiers.cluster,
    node_kind = node_kinds.control_frame,
    actionable = true,
  },
  while_statement = {
    node_tier = node_tiers.cluster,
    node_kind = node_kinds.control_frame,
    actionable = true,
  },
  repeat_statement = {
    node_tier = node_tiers.cluster,
    node_kind = node_kinds.control_frame,
    actionable = true,
  },
  assignment_statement = {
    node_tier = node_tiers.habitat,
    node_kind = node_kinds.assignment,
    actionable = true,
  },
  assignment_expression = {
    node_tier = node_tiers.habitat,
    node_kind = node_kinds.assignment,
    actionable = true,
  },
  variable_declaration = {
    node_tier = node_tiers.habitat,
    node_kind = node_kinds.assignment,
    actionable = true,
  },
  local_declaration = {
    node_tier = node_tiers.habitat,
    node_kind = node_kinds.assignment,
    actionable = true,
  },
  function_call = {
    node_tier = node_tiers.habitat,
    node_kind = node_kinds.call,
    actionable = true,
  },
}

return M
