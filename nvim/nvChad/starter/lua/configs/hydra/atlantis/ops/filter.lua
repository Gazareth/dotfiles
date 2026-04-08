local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Allowed action ids for parsed anchor type
function M.get_node_action_ids(parsed_anchor)
  local node_kind = parsed_anchor and parsed_anchor.node_kind
  if type(node_kind) ~= "string" then
    return nil
  end

  return node_actions.get_node_action_ids(node_kind)
end

-- Check whether one action applies to this parsed anchor
function M.is_action_applicable(parsed_anchor, action_id)
  if type(action_id) ~= "string" or action_id == "" then
    return true
  end

  local node_kind = parsed_anchor and parsed_anchor.node_kind
  if type(node_kind) ~= "string" then
    return true
  end

  return node_actions.is_action_id_applicable(node_kind, action_id)
end

-- Drop menu rows for non-applicable actions
function M.filter_items(parsed_anchor, items)
  if type(items) ~= "table" then
    return items
  end

  local filtered = {}

  -- Keep applicable menu rows only
  for _, item in ipairs(items) do
    if type(item) ~= "table" then
      filtered[#filtered + 1] = item
    elseif M.is_action_applicable(parsed_anchor, item.action_id) then
      filtered[#filtered + 1] = item
    end
  end

  return filtered
end

return M
