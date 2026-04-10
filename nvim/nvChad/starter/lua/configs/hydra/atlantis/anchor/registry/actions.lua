local action_ids = require("configs.hydra.atlantis.anchor.registry.kinds").action_ids
local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes
local ops_resolver = require("configs.hydra.atlantis.ops.resolver")
local common_actions = require("configs.hydra.atlantis.ops.node_kinds.common")
local function_actions = require("configs.hydra.atlantis.ops.node_kinds.function.call_hierarchy")

local M = {}

-- Action builder callbacks by action name
M.action_builders = {
  change = common_actions.change,
  rename = ops_resolver.builder("rename"),
  select = common_actions.select,
  yank = common_actions.yank,
  delete = common_actions.delete,
  inspect = common_actions.inspect,
  jump_to_lhs = ops_resolver.builder("jump_to_lhs"),
  jump_to_rhs = ops_resolver.builder("jump_to_rhs"),
  view_call_hierarchy = function_actions.view_call_hierarchy,
}

-- Canonical action id lookup by action name
M.action_id_by_name = {
  change = action_ids.change,
  rename = action_ids.rename,
  select = action_ids.select,
  yank = action_ids.yank,
  delete = action_ids.delete,
  inspect = action_ids.inspect,
  jump_to_lhs = action_ids.jump,
  jump_to_rhs = action_ids.jump,
  view_call_hierarchy = action_ids.view_call_hierarchy,
}

-- Allowed action names by node kind
M.action_names_by_node_kind = {
  [supported_nodes.generic] = {
    change = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
  [supported_nodes.identifier] = {
    rename = true,
    change = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
  [supported_nodes.assignment] = {
    rename = true,
    jump_to_lhs = true,
    jump_to_rhs = true,
    change = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
  [supported_nodes.fn] = {
    rename = true,
    view_call_hierarchy = true,
    select = true,
    yank = true,
    delete = true,
    inspect = true,
  },
}

-- Check whether action name is allowed for node kind
function M.is_action_name_applicable(node_kind, action_name)
  if not node_kind or not action_name then
    return false
  end

  local actions = M.action_names_by_node_kind[node_kind]
  return type(actions) == "table" and actions[action_name] == true
end

-- Build node action closure when action is allowed
function M.build(node_kind, action_name, ctx)
  if not M.is_action_name_applicable(node_kind, action_name) then
    return nil
  end

  local builder = M.action_builders[action_name]
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {}, node_kind)
end

-- Derive allowed action ids table for given node kind
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

-- Check whether action id is allowed for node kind
function M.is_action_id_applicable(node_kind, action_id)
  if not node_kind or not action_id then
    return false
  end

  local actions = M.get_node_action_ids(node_kind)
  return actions and actions[action_id] == true
end

return M
