-- Common syntax node mappings shared by language schemas
local constants = require("configs.hydra.atlantis-deprecated.schema.constants")

local nt = constants.node_tiers
local nk = constants.node_kinds

return {
  mappings = {
    -- Structural-only nodes: not actionable as anchors, but bound sibling scope
    chunk           = { actionable = false, container = true },
    block           = { actionable = false, container = true },
    statement_block = { actionable = false, container = true },

    class_declaration = {
      node_tier = nt.settlement,
      node_kind = nk.declaration,
      actionable = true,
    },
    function_declaration = {
      node_tier = nt.settlement,
      node_kind = nk.declaration,
      actionable = true,
      container = true,
    },
    function_definition = {
      node_tier = nt.settlement,
      node_kind = nk.declaration,
      actionable = true,
      container = true,
    },
    parameters = {
      node_tier = nt.grove,
      node_kind = nk.collection,
      actionable = true,
      container = true,
    },
    parameter_list = {
      node_tier = nt.grove,
      node_kind = nk.collection,
      actionable = true,
      container = true,
    },
    formal_parameters = {
      node_tier = nt.grove,
      node_kind = nk.collection,
      actionable = true,
      container = true,
    },
    arguments = {
      node_tier = nt.grove,
      node_kind = nk.collection,
      actionable = true,
      container = true,
    },
    if_statement = {
      node_tier = nt.cluster,
      node_kind = nk.control_frame,
      actionable = true,
      container = true,
    },
    for_statement = {
      node_tier = nt.cluster,
      node_kind = nk.control_frame,
      actionable = true,
      container = true,
    },
    while_statement = {
      node_tier = nt.cluster,
      node_kind = nk.control_frame,
      actionable = true,
      container = true,
    },
    repeat_statement = {
      node_tier = nt.cluster,
      node_kind = nk.control_frame,
      actionable = true,
      container = true,
    },
    assignment_statement = {
      node_tier = nt.habitat,
      node_kind = nk.assignment,
      actionable = true,
    },
    assignment_expression = {
      node_tier = nt.habitat,
      node_kind = nk.assignment,
      actionable = true,
    },
    variable_declaration = {
      node_tier = nt.habitat,
      node_kind = nk.assignment,
      actionable = true,
    },
    local_declaration = {
      node_tier = nt.habitat,
      node_kind = nk.assignment,
      actionable = true,
    },
    function_call = {
      node_tier = nt.habitat,
      node_kind = nk.call,
      actionable = true,
    },
    return_statement = {
      node_tier = nt.habitat,
      node_kind = nk.statement,
      actionable = true,
    },
  },
}
