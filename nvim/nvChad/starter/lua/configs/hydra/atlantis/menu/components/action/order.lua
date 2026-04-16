local action_schema = require("configs.hydra.atlantis.schema.actions")

local M = {}

local function role_of(action_name)
  local r = action_schema.action_role and action_schema.action_role[action_name]
  if r == "specific" then
    return "specific"
  end
  return "common"
end

local function enabled_set(anchor_kind)
  return action_schema.action_names_by_anchor_kind and action_schema.action_names_by_anchor_kind[anchor_kind]
end

--- Ordered action names (flat: primary common + overflow common + specific). Kept for callers that need one list.
function M.build(anchor_kind)
  local g = M.build_grouped(anchor_kind)
  local out = {}
  for _, name in ipairs(g.common_primary) do
    out[#out + 1] = name
  end
  for _, name in ipairs(g.common_overflow) do
    out[#out + 1] = name
  end
  for _, name in ipairs(g.specific) do
    out[#out + 1] = name
  end
  return out
end

--- Split enabled actions for Action column: common primary, common overflow, anchor-specific.
function M.build_grouped(anchor_kind)
  local enabled = enabled_set(anchor_kind)
  if type(enabled) ~= "table" then
    return { common_primary = {}, common_overflow = {}, specific = {} }
  end

  local primary = {}
  local overflow = {}
  local specific = {}
  local seen_primary = {}
  local seen_overflow = {}
  local seen_specific = {}

  local function push_unique(list, seen, name)
    if seen[name] then
      return
    end
    seen[name] = true
    list[#list + 1] = name
  end

  -- Primary common
  for _, action_name in ipairs(action_schema.common_primary_order or {}) do
    if enabled[action_name] == true and role_of(action_name) == "common" then
      push_unique(primary, seen_primary, action_name)
    end
  end

  -- Overflow common (explicit order)
  for _, action_name in ipairs(action_schema.common_overflow_order or {}) do
    if enabled[action_name] == true and role_of(action_name) == "common" and not seen_primary[action_name] then
      push_unique(overflow, seen_overflow, action_name)
    end
  end

  -- Remaining enabled common actions (alphabetical)
  local common_extras = {}
  for action_name, is_on in pairs(enabled) do
    if
      is_on == true
      and role_of(action_name) == "common"
      and not seen_primary[action_name]
      and not seen_overflow[action_name]
    then
      common_extras[#common_extras + 1] = action_name
    end
  end
  table.sort(common_extras)
  for _, action_name in ipairs(common_extras) do
    push_unique(overflow, seen_overflow, action_name)
  end

  -- Specific: schema order then sorted extras
  for _, action_name in ipairs(action_schema.specific_action_order or {}) do
    if enabled[action_name] == true and role_of(action_name) == "specific" then
      push_unique(specific, seen_specific, action_name)
    end
  end

  local specific_extras = {}
  for action_name, is_on in pairs(enabled) do
    if is_on == true and role_of(action_name) == "specific" and not seen_specific[action_name] then
      specific_extras[#specific_extras + 1] = action_name
    end
  end
  table.sort(specific_extras)
  for _, action_name in ipairs(specific_extras) do
    push_unique(specific, seen_specific, action_name)
  end

  return {
    common_primary = primary,
    common_overflow = overflow,
    specific = specific,
  }
end

return M
