local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

local M = {}

local generic_anchor_actions = {
  change = true,
  select = true,
  yank = true,
  delete = true,
  inspect = true,
}

local rename_anchor_actions = vim.tbl_extend("force", { rename = true }, generic_anchor_actions)
local assignment_anchor_actions = vim.tbl_extend("force", {
  jump_lhs = true,
  jump_rhs = true,
  rescope = true,
}, rename_anchor_actions)
local function_anchor_actions = vim.tbl_extend("force", {
  jump_to_body = true,
  jump_to_parameter = true,
  jump_to_return = true,
  jump_to_child = true,
  view_call_hierarchy = true,
}, rename_anchor_actions)

local parameter_anchor_actions = vim.tbl_extend("force", {
  jump_function_header = true,
  jump_prev_parameter = true,
  jump_next_parameter = true,
}, rename_anchor_actions)

local binary_anchor_actions = vim.tbl_extend("force", {
  jump_lhs = true,
  jump_rhs = true,
}, rename_anchor_actions)

local body_anchor_actions = vim.tbl_extend("force", {
  jump_to_parent_signature = true,
}, rename_anchor_actions)

local return_anchor_actions = vim.tbl_extend("force", {
  jump_to_enclosing_function = true,
}, rename_anchor_actions)

M.action_names_by_anchor_kind = {
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
