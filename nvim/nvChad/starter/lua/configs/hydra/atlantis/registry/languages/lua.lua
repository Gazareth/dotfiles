-- Lua-specific syntax node mappings layered over common mappings
local constants = require("configs.hydra.atlantis.registry.constants")

local nt = constants.node_tiers
local nk = constants.node_kinds

return {
  mappings = {
    local_function = {
      node_tier = nt.settlement,
      node_kind = nk.declaration,
      actionable = true,
    },
    field_expression = {
      node_tier = nt.chambers,
      node_kind = nk.property,
      actionable = true,
    },
    ["then"] = {
      node_tier = nt.coral,
      node_kind = nk.keyword,
      actionable = false,
    },
    [","] = {
      node_tier = nt.reef,
      node_kind = nk.delimiter,
      actionable = false,
    },
  },
}
