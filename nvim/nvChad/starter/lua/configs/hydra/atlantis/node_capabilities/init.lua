-- Build capability payload for a node kind by combining actions, adapter, and lookup
local node_actions = require("configs.hydra.atlantis.anchor.actions")
local adapters = require("configs.hydra.atlantis.node_capabilities.adapters")
local lookup = require("configs.hydra.atlantis.node_capabilities.lookup")

local M = {}

-- Build full capability payload for menu and action wiring
function M.build(node_kind, runtime_ctx)
  local adapter = adapters.build(node_kind, runtime_ctx)

  return {
    node_kind = node_kind,
    action_ids = node_actions.get_anchor_action_ids(node_kind),
    adapter = adapter,
    lookup = lookup.build(node_kind, runtime_ctx, adapter),
  }
end

return M
