local build_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info
local resolve_language_mapping = require("configs.hydra.atlantis.treesitter.languages").resolve
local treesitter_config = require("configs.hydra.atlantis.treesitter.config")
local constants = require("configs.hydra.atlantis.treesitter.anchor.constants")

local M = {}

-- Resolver options from current config
local function build_resolve_options(config)
  return {
    safe_languages = config.safe_languages,
    languages = config.languages,
  }
end

-- Check whether this node can drive actions
local function is_actionable(node_info, resolve_options)
  local semantic = resolve_language_mapping(node_info, resolve_options)
  if semantic and semantic.actionable == true then
    return true, semantic
  end

  return false, semantic
end

-- Depth mode parse
local function parse_depth_mode(mode)
  if type(mode) ~= "string" then
    return nil
  end

  local value = mode:match("^depth_(%d+)$")
  if not value then
    return nil
  end

  return tonumber(value)
end

-- Score a candidate node for depth_0 selection
-- Returns tier and kind scores used to rank which node is "best"
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

-- Find best anchor by scoring: prefer higher tiers, then simpler kinds, then closest
local function select_standard_anchor_index(candidates)
  local best = nil

  -- Score each node from the tree above the cursor to find the best one to open the menu on
  -- - prefer functions over assignments, assignments over calls
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

-- Pick anchor based on depth mode
-- depth_0: find the best node overall (preference-based)
-- depth_N: only consider shallower tiers, pick closest
local function select_by_mode(candidates, mode)
  if mode == "lowest_node" or mode == "max" then
    return candidates[1].node_info
  end

  -- Closest Settlement with tier/kind preference
  if mode == "depth_0" then
    local standard_index = select_standard_anchor_index(candidates)
    return candidates[standard_index].node_info
  end

  -- For depth_1+, filter out upper tiers and pick the closest remaining node
  local depth = parse_depth_mode(mode)
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

  -- Fallback to closest Settlement behavior
  local standard_index = select_standard_anchor_index(candidates)
  return candidates[standard_index].node_info
end

-- Actionable candidates from cursor chain
local function collect_candidates(node_info, resolve_options)
  local current = node_info and node_info.node or nil
  local candidates = {}

  while current do
    local candidate = build_node_info({
      bufnr = node_info.bufnr,
      node = current,
    })

    local actionable, semantic = false, nil
    if candidate then
      actionable, semantic = is_actionable(candidate, resolve_options)
    end

    if candidate and actionable then
      candidates[#candidates + 1] = {
        node_info = candidate,
        semantic = semantic,
      }
    end

    current = current:parent()
  end

  return candidates
end

-- Public anchor candidate list
function M.get_candidates(node_info)
  if not node_info or not node_info.node then
    return {}
  end

  local config = treesitter_config.get()
  local resolve_options = build_resolve_options(config)
  return collect_candidates(node_info, resolve_options)
end

-- Candidate index for selected node
function M.find_candidate_index(candidates, selected_node_info)
  if type(candidates) ~= "table" or not selected_node_info or not selected_node_info.node then
    return nil
  end

  local ok, selected_id = pcall(function()
    return selected_node_info.node:id()
  end)
  if not ok then
    return nil
  end

  for index, entry in ipairs(candidates) do
    local match_ok, entry_id = pcall(function()
      return entry.node_info.node:id()
    end)
    if match_ok and entry_id == selected_id then
      return index
    end
  end

  return nil
end

-- Choose the action anchor from the cursor node chain
function M.select_node_info(node_info)
  if not node_info or not node_info.node then
    return node_info
  end

  local config = treesitter_config.get()
  local mode = config.context_mode or "depth_0"
  local candidates = M.get_candidates(node_info)

  if #candidates == 0 then
    return node_info
  end

  return select_by_mode(candidates, mode)
end

return M