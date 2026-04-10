local atlantis_constants = require("configs.hydra.atlantis.anchor.registry.kinds")
local node_tiers = atlantis_constants.node_tiers
local node_kinds = atlantis_constants.node_kinds

local M = {}

-- Atlantis node tiers passthrough
M.node_tiers = node_tiers

-- Standard anchor tiers
M.standard_preferred_tiers = {
  [node_tiers.colony] = true,
  [node_tiers.settlement] = true,
  [node_tiers.cluster] = true,
  [node_tiers.habitat] = true,
}

-- Standard tier context_depth score
M.standard_tier_context_depth = {
  [node_tiers.colony] = 4,
  [node_tiers.settlement] = 3,
  [node_tiers.cluster] = 2,
  [node_tiers.habitat] = 1,
}

-- Tier depth map for depth_N filtering
M.depth_tier_context_depth = {
  [node_tiers.colony] = 4,
  [node_tiers.settlement] = 3,
  [node_tiers.grove] = 2,
  [node_tiers.cluster] = 2,
  [node_tiers.habitat] = 1,
}

-- Habitat kind context_depth score
M.habitat_kind_context_depth = {
  [node_kinds.assignment] = 1,
  [node_kinds.statement] = 2,
  [node_kinds.call] = 3,
}

return M