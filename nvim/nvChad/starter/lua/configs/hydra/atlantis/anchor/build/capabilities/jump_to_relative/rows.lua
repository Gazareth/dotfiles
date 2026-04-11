local menu_schema = require("configs.hydra.atlantis.schema.menu")
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local probe = require("configs.hydra.atlantis.anchor.probe")
local relative_jumps = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.relative_jumps")
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

local function relation_phrase(relation)
  local t = jump_cfg.relation_phrase and jump_cfg.relation_phrase[relation]
  if type(t) == "string" then
    return t
  end
  return "To " .. string.gsub(relation or "target", "_", " ")
end

local function row_label_from_quoted(phrase, quoted)
  if type(quoted) ~= "string" or quoted == "" then
    return phrase
  end
  return string.format("%s - %s", phrase, quoted)
end

local function append_relation_items(items, labeled)
  local last_group = nil
  for _, row in ipairs(jump_cfg.items or {}) do
    if type(row.relation) == "string" then
      if row.group ~= last_group then
        append_group_heading(items, row.group)
        last_group = row.group
      end
      local L = labeled[row.relation]
      local target = L and L.target
      local quoted = L and L.quoted
      local item
      if row.relation == "parent" and target and targets.is_document_root(target) then
        local dr = jump_cfg.document_root_jump
        local phrase = type(dr) == "table" and dr.label_phrase or "To top"
        item = {
          key = row.key,
          icon = type(dr) == "table" and dr.icon or "⇪",
          label = row_label_from_quoted(phrase, quoted),
          action = targets.jump_action(target),
        }
      elseif target and quoted then
        item = {
          key = row.key,
          icon = row.icon,
          label = row_label_from_quoted(relation_phrase(row.relation), quoted),
          action = targets.jump_action(target),
        }
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

local function context_phrase(which)
  local t = jump_cfg.context_phrase and jump_cfg.context_phrase[which]
  if type(t) == "string" then
    return t
  end
  return which == "higher" and "To higher in context" or "To lower in context"
end

local function context_neighbor_label(candidate_index, candidate, jump_labels)
  if type(candidate) ~= "table" or type(candidate.node_info) ~= "table" then
    return nil
  end
  local q = jump_labels and jump_labels[candidate_index]
  if type(q) == "string" and q ~= "" then
    return q
  end
  return menu_labels.quoted_target(candidate.node_info, probe.parse(candidate.node_info))
end

local function append_context_items(items, candidates, selected_index, jump_labels)
  if type(selected_index) ~= "number" then
    return
  end

  local higher_spec = context_row_spec("higher")
  local lower_spec = context_row_spec("lower")
  local has_context_items = false

  if selected_index < #candidates then
    local higher = candidates[selected_index + 1]
    if not has_context_items then
      append_group_heading(items, "context")
      has_context_items = true
    end
    items[#items + 1] = {
      key = higher_spec and higher_spec.key or "h",
      icon = higher_spec and higher_spec.icon or "⬆",
      label = row_label_from_quoted(
        context_phrase("higher"),
        context_neighbor_label(selected_index + 1, higher, jump_labels)
      ),
      action = targets.jump_action(higher and higher.node_info),
    }
  end

  if selected_index > 1 then
    local lower = candidates[selected_index - 1]
    if not has_context_items then
      append_group_heading(items, "context")
      has_context_items = true
    end
    items[#items + 1] = {
      key = lower_spec and lower_spec.key or "l",
      icon = lower_spec and lower_spec.icon or "⬇",
      label = row_label_from_quoted(
        context_phrase("lower"),
        context_neighbor_label(selected_index - 1, lower, jump_labels)
      ),
      action = targets.jump_action(lower and lower.node_info),
    }
  end
end

function M.build_items(anchor_node_info, find_result)
  local items = {}
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil
  local jump_labels = type(find_result) == "table" and find_result.jump_labels or nil

  local labeled = relative_jumps.labeled(anchor_node_info, jump_cfg.items)
  append_relation_items(items, labeled)
  append_context_items(items, candidates, selected_index, jump_labels)

  return items
end

return M
