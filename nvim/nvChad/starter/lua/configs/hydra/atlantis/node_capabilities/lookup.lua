-- Build callable action map for an anchor kind from registry actions and adapter overrides
local node_actions = require("configs.hydra.atlantis.anchor.actions")
local action_registry = require("configs.hydra.atlantis.registry.actions")

local M = {}

-- Build action lookup by merging registry callbacks and adapter overrides
function M.build(anchor_kind, runtime_ctx, adapter)
  local lookup = {}

  -- Collect actions from registry for this anchor kind
  local action_names = action_registry.action_names_by_anchor_kind[anchor_kind]
  if type(action_names) == "table" then
    for action_name, enabled in pairs(action_names) do
      if enabled == true then
        local action = node_actions.build(anchor_kind, action_name, runtime_ctx)
        if type(action) == "function" then
          lookup[action_name] = action
        end
      end
    end
  end

  -- Merge adapter-provided callback overrides
  if type(adapter) == "table" then
    for key, callback in pairs(adapter.capability_actions or {}) do
      if type(key) == "string" and type(callback) == "function" then
        lookup[key] = callback
      end
    end

    for key, callback in pairs(adapter.capability_availability or {}) do
      if type(key) == "string" and type(callback) == "function" then
        lookup[key] = callback
      end
    end
  end

  return lookup
end

return M
