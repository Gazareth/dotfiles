local M = {}
local atlantis_constants = require("configs.hydra.atlantis.treesitter.lib.atlantis.constants")

local nt = atlantis_constants.node_tiers
local nk = atlantis_constants.node_kinds

-- Shared fallback mappings
M.mappings = {
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
}

return M
