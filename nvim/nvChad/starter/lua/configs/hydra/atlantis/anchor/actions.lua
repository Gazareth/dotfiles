-- Resolve and build anchor actions using registry tables and runtime builders
local action_registry = require("configs.hydra.atlantis.registry.actions")
local action_ids = require("configs.hydra.atlantis.registry.constants").action_ids
local ops_resolver = require("configs.hydra.atlantis.ops.resolver")

local M = {}

-- Canonical action names used to assemble resolver-backed action builders
local action_names = {
  "change",
  "rename",
  "select",
  "yank",
  "delete",
  "inspect",
  "jump_lhs",
  "jump_rhs",
  "jump_to_body",
  "jump_to_parameter",
  "view_call_hierarchy",
}

-- Action builder callbacks by action name
local action_builders = {}
for _, action_name in ipairs(action_names) do
  action_builders[action_name] = ops_resolver[action_name]
end

-- Check whether action name is applicable to anchor kind
function M.is_action_name_applicable(anchor_kind, action_name)
  if not anchor_kind or not action_name then
    return false
  end

  local actions = action_registry.action_names_by_anchor_kind[anchor_kind]
  return type(actions) == "table" and actions[action_name] == true
end

-- Build anchor action closure when action is applicable
function M.build(anchor_kind, action_name, ctx)
  if not M.is_action_name_applicable(anchor_kind, action_name) then
    return nil
  end

  local builder = action_builders[action_name]
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {}, anchor_kind)
end

-- Derive applicable action ids table for given anchor kind
function M.get_anchor_action_ids(anchor_kind)
  if type(anchor_kind) ~= "string" then
    return nil
  end

  local action_names = action_registry.action_names_by_anchor_kind[anchor_kind]
  if type(action_names) ~= "table" then
    return nil
  end

  local anchor_action_ids = {}
  for action_name, enabled in pairs(action_names) do
    if enabled == true then
      local action_id = action_ids[action_name]
      if type(action_id) == "string" and action_id ~= "" then
        anchor_action_ids[action_id] = true
      end
    end
  end

  return anchor_action_ids
end

-- Check whether action id is applicable to anchor kind
function M.is_anchor_action_id_applicable(anchor_kind, action_id)
  if not anchor_kind or not action_id then
    return false
  end

  local actions = M.get_anchor_action_ids(anchor_kind)
  return actions and actions[action_id] == true
end

return M
