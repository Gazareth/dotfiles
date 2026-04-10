-- Build action name order for a node kind so rows appear in a stable menu order
local action_registry = require("configs.hydra.atlantis.menu.components.action.registry")
local node_actions = require("configs.hydra.atlantis.anchor.registry.actions")

local M = {}

-- Build deterministic action order with generic actions first
function M.build(node_kind)
  local enabled = node_actions.action_names_by_node_kind
    and node_actions.action_names_by_node_kind[node_kind]
  if type(enabled) ~= "table" then
    -- No node-kind map means no rows
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
