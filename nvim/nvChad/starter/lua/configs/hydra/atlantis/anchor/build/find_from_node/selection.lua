local constants = require("configs.hydra.atlantis.anchor.constants")

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
local function select_standard_anchor_index(candidate_chain)
  local best = nil

  -- Rank parent-chain nodes by tier and kind, then prefer closest tie
  for index, entry in ipairs(candidate_chain) do
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

  return #candidate_chain
end

-- Select anchor candidate node from numeric depth
function M.select_anchor_node_info(candidate_chain, depth)
  if depth <= 0 then
    local standard_index = select_standard_anchor_index(candidate_chain)
    return candidate_chain[standard_index].node_info
  end

  -- Filter by requested depth, then keep the closest surviving candidate
  local max_tier_depth = 3 - depth
  local filtered = {}

  for _, entry in ipairs(candidate_chain) do
    local tier_depth = constants.depth_tier_context_depth[entry.semantic.node_tier]
    if tier_depth and tier_depth <= max_tier_depth then
      filtered[#filtered + 1] = entry
    end
  end

  if #filtered > 0 then
    return filtered[#filtered].node_info
  end

  local standard_index = select_standard_anchor_index(candidate_chain)
  return candidate_chain[standard_index].node_info
end

-- Find selected anchor index inside candidate chain
function M.find_candidate_index(candidate_chain, selected_node_info)
  if type(candidate_chain) ~= "table" or not selected_node_info or not selected_node_info.node then
    return nil
  end

  local ok, selected_id = pcall(function()
    return selected_node_info.node:id()
  end)
  if not ok then
    return nil
  end

  for index, entry in ipairs(candidate_chain) do
    local match_ok, entry_id = pcall(function()
      return entry.node_info.node:id()
    end)
    if match_ok and entry_id == selected_id then
      return index
    end
  end

  return nil
end

return M