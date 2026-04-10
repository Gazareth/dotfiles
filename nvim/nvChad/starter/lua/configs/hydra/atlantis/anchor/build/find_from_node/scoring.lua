local constants = require("configs.hydra.atlantis.anchor.constants")
local options = require("configs.hydra.atlantis.anchor.build.find_from_node.options")

local M = {}

-- Score candidate anchor for standard depth selection
local function get_standard_score(entry)
  local tier = entry.semantic.node_tier
  local kind = entry.semantic.node_kind
  local tier_context_depth = constants.standard_tier_context_depth[tier]
  if not tier_context_depth then
    return nil
  end

  if tier == constants.node_tiers.habitat then
    return tier_context_depth, constants.habitat_kind_context_depth[kind] or 99
  end

  return tier_context_depth, 1
end

-- Select best standard anchor index from actionable candidate chain
local function select_standard_anchor_index(candidates)
  local best = nil

  -- Rank parent-chain nodes by tier and kind, then prefer closest tie
  for index, entry in ipairs(candidates) do
    if constants.standard_preferred_tiers[entry.semantic.node_tier] then
      local tier_context_depth, kind_context_depth = get_standard_score(entry)
      if tier_context_depth then
        if not best
          or tier_context_depth < best.tier_context_depth
          or (tier_context_depth == best.tier_context_depth and kind_context_depth < best.kind_context_depth)
          or (tier_context_depth == best.tier_context_depth and kind_context_depth == best.kind_context_depth and index > best.index) then
          best = {
            index = index,
            tier_context_depth = tier_context_depth,
            kind_context_depth = kind_context_depth,
          }
        end
      end
    end
  end

  if best then
    return best.index
  end

  return #candidates
end

-- Select anchor candidate node by depth mode policy
function M.select_by_mode(candidates, mode)
  if mode == "lowest_node" or mode == "max" then
    return candidates[1].node_info
  end

  -- Standard scored anchor selection
  if mode == "depth_0" then
    local standard_index = select_standard_anchor_index(candidates)
    return candidates[standard_index].node_info
  end

  -- Depth filter then closest surviving candidate
  local depth = options.parse_depth_mode(mode)
  if type(depth) == "number" then
    local max_tier_depth = 3 - depth
    local filtered = {}

    for _, entry in ipairs(candidates) do
      local tier_depth = constants.depth_tier_context_depth[entry.semantic.node_tier]
      if tier_depth and tier_depth <= max_tier_depth then
        filtered[#filtered + 1] = entry
      end
    end

    if #filtered > 0 then
      return filtered[#filtered].node_info
    end
  end

  -- Fallback to standard scored selection
  local standard_index = select_standard_anchor_index(candidates)
  return candidates[standard_index].node_info
end

return M
