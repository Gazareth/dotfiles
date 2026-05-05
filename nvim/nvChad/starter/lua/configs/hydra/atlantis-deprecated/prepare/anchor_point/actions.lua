local action_schema = require("configs.hydra.atlantis-deprecated.schema.actions")
local ops_resolver = require("configs.hydra.atlantis-deprecated.ops.resolver")

local M = {}

function M.is_action_name_applicable(anchor_kind, action_name)
  if not anchor_kind or not action_name then
    return false
  end

  local actions = action_schema.action_names_by_anchor_kind[anchor_kind]
  return type(actions) == "table" and actions[action_name] == true
end

function M.build(anchor_kind, action_name, ctx)
  if not M.is_action_name_applicable(anchor_kind, action_name) then
    return nil
  end

  local builder = ops_resolver[action_name]
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {}, anchor_kind)
end

return M
