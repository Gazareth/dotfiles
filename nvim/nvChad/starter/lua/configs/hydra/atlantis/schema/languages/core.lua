-- Shared fallback mappings across all languages
local constants = require("configs.hydra.atlantis.schema.constants")

local nt = constants.node_tiers
local nk = constants.node_kinds

return {
  mappings = {
    identifier = {
      node_tier = nt.chambers,
      node_kind = nk.identifier,
      actionable = true,
    },
    string = {
      node_tier = nt.chambers,
      node_kind = nk.string,
      actionable = true,
    },
    comment = {
      node_tier = nt.reef,
      node_kind = nk.comment,
      actionable = true,
    },
  },
}
