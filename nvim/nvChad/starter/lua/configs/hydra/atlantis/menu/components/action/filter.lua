local node_actions = require("configs.hydra.atlantis.anchor.registry.actions")

local M = {}

-- Resolve allowed action ids for current parsed anchor kind
function M.get_node_action_ids(parsed_anchor)
  local node_kind = parsed_anchor and parsed_anchor.node_kind
  if type(node_kind) ~= "string" then
    return nil
  end

  return node_actions.get_node_action_ids(node_kind)
end

-- Check whether a menu item action id is allowed for this anchor
function M.is_action_applicable(parsed_anchor, action_id, action_ids)
  if type(action_id) ~= "string" or action_id == "" then
    return true
  end

  if type(action_ids) == "table" then
    return action_ids[action_id] == true
  end

  local node_kind = parsed_anchor and parsed_anchor.node_kind
  if type(node_kind) ~= "string" then
    return true
  end

  return node_actions.is_action_id_applicable(node_kind, action_id)
end

-- Filter menu items down to action rows valid for this anchor
function M.filter_items(parsed_anchor, items, action_ids)
  if type(items) ~= "table" then
    return items
  end

  local filtered = {}

  -- Preserve non-action rows and keep only applicable action rows
  for _, item in ipairs(items) do
    if type(item) ~= "table" then
      filtered[#filtered + 1] = item
    elseif M.is_action_applicable(parsed_anchor, item.action_id, action_ids) then
      filtered[#filtered + 1] = item
    end
  end

  return filtered
end

return M
