local action_ids = require("configs.hydra.atlantis.registry.node_tiers").action_ids
local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Assignment target row
function M.build_row(node_info, parsed, key)
  local targets = type(parsed) == "table" and parsed.targets or nil
  local left = type(targets) == "table" and targets.left or nil
  if type(left) ~= "table" then
    return nil
  end

  return {
    key = key or "h",
    icon = ">",
    label = "Left hand side: " .. tostring(left.name or left.label or "left hand side"),
    action_id = action_ids.jump,
    action = node_actions.build("assignment", "jump_to_lhs", {
      node_info = node_info,
      parsed = parsed,
      target = left,
    }),
  }
end

return M
