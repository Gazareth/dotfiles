local M = {}
local atlantis_constants = require("configs.hydra.atlantis.anchor.registry.kinds")
local node_tiers = atlantis_constants.node_tiers
local node_kinds = atlantis_constants.node_kinds

-- Base Lua node mappings
M.mappings = {
  local_function = {
    node_tier = node_tiers.settlement,
    node_kind = node_kinds.declaration,
    actionable = true,
  },
  field_expression = {
    node_tier = node_tiers.chambers,
    node_kind = node_kinds.property,
    actionable = true,
  },
  ["then"] = {
    node_tier = node_tiers.coral,
    node_kind = node_kinds.keyword,
    actionable = false,
  },
  [","] = {
    node_tier = node_tiers.reef,
    node_kind = node_kinds.delimiter,
    actionable = false,
  },
}

return M
