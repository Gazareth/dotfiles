local action_ids = require("configs.hydra.atlantis.registry.node_tiers").action_ids
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local common_actions = require("configs.hydra.atlantis.ops.common")
local function_actions = require("configs.hydra.atlantis.ops.functions")
local assignment_actions = require("configs.hydra.atlantis.ops.assignments")

local M = {}

-- Action builders by action name
M.action_builders = {
  change = common_actions.change,
  select = common_actions.select,
  yank = common_actions.yank,
  delete = common_actions.delete,
  inspect = common_actions.inspect,
  jump = common_actions.jump,
  jump_to_lhs = assignment_actions.jump_to_lhs,
  jump_to_rhs = assignment_actions.jump_to_rhs,
  change_name = function_actions.change_name,
  view_call_hierarchy = function_actions.view_call_hierarchy,
}

-- Action id by action name
M.action_id_by_name = {
  change = action_ids.change,
  select = action_ids.select,
  yank = action_ids.yank,
  delete = action_ids.delete,
  inspect = action_ids.inspect,
  jump = action_ids.jump,
  jump_to_lhs = action_ids.jump,
  jump_to_rhs = action_ids.jump,
  change_name = action_ids.change_name,
  view_call_hierarchy = action_ids.view_call_hierarchy,
}

-- Action names mapped by node kind
M.action_names_by_node_kind = {
  [supported_nodes.generic] = {
    change = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
  [supported_nodes.identifier] = {
    change = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
  [supported_nodes.assignment] = {
    jump_to_lhs = true,
    jump_to_rhs = true,
    change = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
  [supported_nodes.fn] = {
    change_name = true,
    view_call_hierarchy = true,
    jump = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
}

-- Check whether action name applies to node kind
function M.is_action_name_applicable(node_kind, action_name)
  if not node_kind or not action_name then
    return false
  end

  local actions = M.action_names_by_node_kind[node_kind]
  return type(actions) == "table" and actions[action_name] == true
end

-- Build action closure from node kind and action name
function M.build(node_kind, action_name, ctx)
  if not M.is_action_name_applicable(node_kind, action_name) then
    return nil
  end

  local builder = M.action_builders[action_name]
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {})
end

-- Node action ids derived from node kind action names
function M.get_node_action_ids(node_kind)
  if type(node_kind) ~= "string" then
    return nil
  end

  local action_names = M.action_names_by_node_kind[node_kind]
  if type(action_names) ~= "table" then
    return nil
  end

  local node_action_ids = {}
  for action_name, enabled in pairs(action_names) do
    if enabled == true then
      local action_id = M.action_id_by_name[action_name]
      if type(action_id) == "string" and action_id ~= "" then
        node_action_ids[action_id] = true
      end
    end
  end

  return node_action_ids
end

-- Check whether action id applies to node kind
function M.is_action_id_applicable(node_kind, action_id)
  if not node_kind or not action_id then
    return false
  end

  local actions = M.get_node_action_ids(node_kind)
  return actions and actions[action_id] == true
end

return M
