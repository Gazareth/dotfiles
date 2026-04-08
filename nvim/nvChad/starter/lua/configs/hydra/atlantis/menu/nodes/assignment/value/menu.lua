local action_ids = require("configs.hydra.atlantis.registry.node_tiers").action_ids
local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Assignment value row
function M.build_row(node_info, parsed, key)
  local targets = type(parsed) == "table" and parsed.targets or nil
  local right = type(targets) == "table" and targets.right or nil
  if type(right) ~= "table" then
    return nil
  end

  return {
    key = key or "l",
    icon = ">",
    label = "Right hand side: " .. tostring(right.name or right.label or "right hand side"),
    action_id = action_ids.jump,
    action = node_actions.build("assignment", "jump_to_rhs", {
      node_info = node_info,
      parsed = parsed,
      target = right,
    }),
  }
end

return M
