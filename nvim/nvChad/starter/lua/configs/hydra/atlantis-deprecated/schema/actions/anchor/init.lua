local supported_nodes = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.constants").supported_nodes

local M = {}

local function extend_actions(base, additions)
  return vim.tbl_extend("force", additions, base)
end

local generic_anchor_actions = {
  change = true,
  select = true,
  yank = true,
  delete = true,
  inspect = true,
  jump_to_comment = true,
}

local comment_anchor_actions = {
  jump_to_commented_statement = true,
}

local rename_anchor_actions     = extend_actions(generic_anchor_actions, { rename = true })
local assignment_anchor_actions = extend_actions(rename_anchor_actions, {
  jump_lhs = true,
  jump_rhs = true,
  rescope = true,
})
local function_anchor_actions   = extend_actions(rename_anchor_actions, {
  jump_to_body = true,
  jump_to_parameter = true,
  jump_to_return = true,
  jump_to_child = true,
  view_call_hierarchy = true,
})
local parameter_anchor_actions  = extend_actions(rename_anchor_actions, {
  jump_function_header = true,
  jump_prev_parameter = true,
  jump_next_parameter = true,
})
local binary_anchor_actions     = extend_actions(rename_anchor_actions, {
  jump_lhs = true,
  jump_rhs = true,
})
local body_anchor_actions       = extend_actions(rename_anchor_actions, {
  jump_to_parent_signature = true,
})
local return_anchor_actions     = extend_actions(rename_anchor_actions, {
  jump_to_enclosing_function = true,
})

M.action_names_by_anchor_kind = {
  ["comment"] = comment_anchor_actions,
  [supported_nodes.generic] = generic_anchor_actions,
  [supported_nodes.identifier] = rename_anchor_actions,
  [supported_nodes.assignment] = assignment_anchor_actions,
  [supported_nodes.fn] = function_anchor_actions,
  [supported_nodes.parameter] = parameter_anchor_actions,
  [supported_nodes.binary_expression] = binary_anchor_actions,
  [supported_nodes.body] = body_anchor_actions,
  [supported_nodes.return_stmt] = return_anchor_actions,
}

return M
