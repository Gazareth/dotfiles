local M = {}

-- Turn an action list into quick key lookups
local function list_to_set(items)
  local set = {}
  if type(items) ~= "table" then
    return set
  end

  for _, item in ipairs(items) do
    if type(item) == "string" and item ~= "" then
      set[item] = true
    end
  end

  return set
end

-- Combine global, tier, and kind action rules
function M.get_allowed_actions(parsed)
  local semantic = parsed and parsed.semantic
  if type(semantic) ~= "table" then
    return nil
  end

  local action_matrix = semantic.action_matrix
  local node_tier = parsed and parsed.node_tier
  local node_kind = parsed and parsed.semantic_kind

  if type(action_matrix) ~= "table" or type(node_tier) ~= "string" or type(node_kind) ~= "string" then
    return nil
  end

  local tier_table = action_matrix[node_tier]
  local allowed = {}
  local has_rule = false

  -- Global defaults first
  if type(action_matrix._default) == "table" then
    allowed = vim.tbl_extend("force", allowed, list_to_set(action_matrix._default))
    has_rule = true
  end

  if type(tier_table) == "table" then
    -- Tier defaults before kind rules
    if type(tier_table._default) == "table" then
      allowed = vim.tbl_extend("force", allowed, list_to_set(tier_table._default))
      has_rule = true
    end

    if type(tier_table[node_kind]) == "table" then
      allowed = vim.tbl_extend("force", allowed, list_to_set(tier_table[node_kind]))
      has_rule = true
    end
  end

  if not has_rule then
    return nil
  end

  return allowed
end

-- Check whether one action is allowed here
function M.allows(parsed, action_id)
  if type(action_id) ~= "string" or action_id == "" then
    return true
  end

  local allowed = M.get_allowed_actions(parsed)
  if type(allowed) ~= "table" then
    return true
  end

  return allowed[action_id] == true
end

-- Drop menu rows for blocked actions
function M.filter_items(parsed, items)
  if type(items) ~= "table" then
    return items
  end

  local filtered = {}

  -- Keep allowed menu rows only
  for _, item in ipairs(items) do
    if type(item) ~= "table" then
      filtered[#filtered + 1] = item
    elseif M.allows(parsed, item.action_id) then
      filtered[#filtered + 1] = item
    end
  end

  return filtered
end

return M
