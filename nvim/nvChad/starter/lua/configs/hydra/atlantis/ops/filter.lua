local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Allowed action ids for parsed anchor type
function M.get_allowed_actions(parsed_anchor)
  local node_kind = parsed_anchor and parsed_anchor.node_kind
  if type(node_kind) ~= "string" then
    return nil
  end

  return node_actions.get_allowed_action_ids(node_kind)
end

-- Check whether one action is allowed for this parsed anchor
function M.allows(parsed_anchor, action_id)
  if type(action_id) ~= "string" or action_id == "" then
    return true
  end

  local node_kind = parsed_anchor and parsed_anchor.node_kind
  if type(node_kind) ~= "string" then
    return true
  end

  return node_actions.is_available(node_kind, action_id)
end

-- Drop menu rows for blocked actions
function M.filter_items(parsed_anchor, items)
  if type(items) ~= "table" then
    return items
  end

  local filtered = {}

  -- Keep allowed menu rows only
  for _, item in ipairs(items) do
    if type(item) ~= "table" then
      filtered[#filtered + 1] = item
    elseif M.allows(parsed_anchor, item.action_id) then
      filtered[#filtered + 1] = item
    end
  end

  return filtered
end

return M
