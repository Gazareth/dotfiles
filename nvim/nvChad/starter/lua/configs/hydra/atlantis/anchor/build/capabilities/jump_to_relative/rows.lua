local parse_node = require("configs.hydra.atlantis.anchor.probe")
local menu_schema = require("configs.hydra.atlantis.schema.menu")
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")

local M = {}

local jump_cfg = menu_schema.jump

local function append_group_heading(items, group_id)
  local label = jump_cfg.group_labels and jump_cfg.group_labels[group_id]
  if type(label) ~= "string" or label == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = label }
  items[#items + 1] = { separator = true }
end

local function build_target_item(key, icon, target_node_info)
  if not target_node_info then
    return nil
  end

  local parsed = parse_node(target_node_info)
  return {
    key = key,
    icon = icon,
    label = menu_labels.build_label(target_node_info, parsed),
    action = targets.jump_action(target_node_info),
  }
end

local function append_relation_items(items, selected_node_info)
  local last_group = nil
  for _, row in ipairs(jump_cfg.items or {}) do
    if type(row.relation) == "string" then
      if row.group ~= last_group then
        append_group_heading(items, row.group)
        last_group = row.group
      end
      local target = targets.resolve(selected_node_info, row.relation)
      local item
      if row.relation == "parent" and target and targets.is_document_root(target) then
        local dr = jump_cfg.document_root_jump
        item = {
          key = row.key,
          icon = type(dr) == "table" and dr.icon or "⇪",
          label = type(dr) == "table" and dr.label or "Go to top",
          action = targets.jump_action(target),
        }
      else
        item = build_target_item(row.key, row.icon, target)
      end
      if item then
        items[#items + 1] = item
      end
    end
  end
end

local function context_row_spec(which)
  for _, row in ipairs(jump_cfg.items or {}) do
    if row.context == which then
      return row
    end
  end
  return nil
end

local function append_context_items(items, candidates, selected_index)
  if type(selected_index) ~= "number" then
    return
  end

  local higher_spec = context_row_spec("higher")
  local lower_spec = context_row_spec("lower")
  local has_context_items = false

  if selected_index < #candidates then
    local higher = candidates[selected_index + 1]
    local higher_parsed = higher and parse_node(higher.node_info) or nil
    if not has_context_items then
      append_group_heading(items, "context")
      has_context_items = true
    end
    items[#items + 1] = {
      key = higher_spec and higher_spec.key or "h",
      icon = higher_spec and higher_spec.icon or "⬆",
      label = menu_labels.build_label(higher and higher.node_info, higher_parsed),
      action = targets.jump_action(higher and higher.node_info),
    }
  end

  if selected_index > 1 then
    local lower = candidates[selected_index - 1]
    local lower_parsed = lower and parse_node(lower.node_info) or nil
    if not has_context_items then
      append_group_heading(items, "context")
      has_context_items = true
    end
    items[#items + 1] = {
      key = lower_spec and lower_spec.key or "l",
      icon = lower_spec and lower_spec.icon or "⬇",
      label = menu_labels.build_label(lower and lower.node_info, lower_parsed),
      action = targets.jump_action(lower and lower.node_info),
    }
  end
end

function M.build_items(anchor_node_info, find_result)
  local items = {}
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil

  append_relation_items(items, anchor_node_info)
  append_context_items(items, candidates, selected_index)

  return items
end

return M
