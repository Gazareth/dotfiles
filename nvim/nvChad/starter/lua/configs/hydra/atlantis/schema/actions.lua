-- Action lookup tables keyed by semantic node kind
local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

local M = {}

-- Reusable generic action groups for composing anchor action sets
local generic_anchor_actions = {
  change = true,
  select = true,
  yank = true,
  delete = true,
  inspect = true,
}

local rename_anchor_actions = vim.tbl_extend("force", { rename = true }, generic_anchor_actions)
local assignment_anchor_actions = vim.tbl_extend("force", { jump_lhs = true, jump_rhs = true }, rename_anchor_actions)
local function_anchor_actions = vim.tbl_extend("force", {
  jump_to_body = true,
  jump_to_parameter = true,
  view_call_hierarchy = true,
}, rename_anchor_actions)

-- Allowed action names by anchor kind
M.action_names_by_anchor_kind = {
  [supported_nodes.generic] = generic_anchor_actions,
  [supported_nodes.identifier] = rename_anchor_actions,
  [supported_nodes.assignment] = assignment_anchor_actions,
  [supported_nodes.fn] = function_anchor_actions,
}

return M
