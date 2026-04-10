-- Build capability payload for a node kind by combining action ids, adapter, lookup, and submenu specs
local node_actions = require("configs.hydra.atlantis.anchor.registry.actions")
local adapters = require("configs.hydra.atlantis.registry.node_capabilities.adapters")
local lookup = require("configs.hydra.atlantis.registry.node_capabilities.lookup")
local submenus = require("configs.hydra.atlantis.registry.node_capabilities.submenus")

local M = {}

-- Resolve allowed action ids by node kind
function M.by_node_kind(node_kind)
  return node_actions.get_node_action_ids(node_kind)
end

-- Build node adapter instance from adapter spec table
function M.build_adapter(node_kind, runtime_ctx)
  return adapters.build(node_kind, runtime_ctx)
end

-- Build full capability payload for menu and action wiring
function M.build(node_kind, runtime_ctx)
  local adapter = M.build_adapter(node_kind, runtime_ctx)

  return {
    node_kind = node_kind,
    action_ids = M.by_node_kind(node_kind),
    adapter = adapter,
    lookup = lookup.build(node_kind, runtime_ctx, adapter),
    submenus = submenus.build(node_kind, runtime_ctx, adapter),
  }
end

return M
