local action_ids = require("configs.hydra.atlantis.registry.node_tiers").action_ids
local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Action spec constructor
local function action_spec(name, key, icon, action_id, label_text)
  -- Action label builder
  local label_builder = function(label)
    return label_text .. " " .. label
  end

  return {
    name = name,
    key = key,
    icon = icon,
    action_id = action_id,
    label_builder = label_builder,
  }
end

-- Generic action presentation map
local generic_action_specs = {
  action_spec("change", "c", ">", action_ids.change, "Change"),
  action_spec("yank", "y", "=", action_ids.yank, "Yank"),
  action_spec("select", "v", "=", action_ids.select, "Select"),
  action_spec("delete", "d", "x", action_ids.delete, "Delete"),
  action_spec("inspect", "i", "?", action_ids.inspect, "Inspect node mapping"),
}

-- Generic action rows for menu builders
function M.build_generic_action_rows(anchor_type, label, ctx)
  local rows = {}

  for _, spec in ipairs(generic_action_specs) do
    rows[#rows + 1] = {
      key = spec.key,
      icon = spec.icon,
      label = spec.label_builder(label),
      action_id = spec.action_id,
      action = node_actions.build(anchor_type, spec.name, ctx),
    }
  end

  return rows
end

return M