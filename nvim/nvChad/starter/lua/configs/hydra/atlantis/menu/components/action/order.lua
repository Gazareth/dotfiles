-- Build action name order for an anchor kind so rows appear in a stable menu order
local action_registry = require("configs.hydra.atlantis.menu.components.action.registry")
local action_tables = require("configs.hydra.atlantis.registry.actions")

local M = {}

-- Build deterministic action order with generic actions first
function M.build(anchor_kind)
  local enabled = action_tables.action_names_by_anchor_kind
    and action_tables.action_names_by_anchor_kind[anchor_kind]
  if type(enabled) ~= "table" then
    return {}
  end

  local ordered = {}
  local seen = {}

  for _, action_name in ipairs(action_registry.generic_action_order or {}) do
    if enabled[action_name] == true then
      ordered[#ordered + 1] = action_name
      seen[action_name] = true
    end
  end

  local extras = {}
  for action_name, is_enabled in pairs(enabled) do
    if is_enabled == true and not seen[action_name] then
      extras[#extras + 1] = action_name
      seen[action_name] = true
    end
  end

  table.sort(extras)
  for _, action_name in ipairs(extras) do
    ordered[#ordered + 1] = action_name
  end

  return ordered
end

return M
