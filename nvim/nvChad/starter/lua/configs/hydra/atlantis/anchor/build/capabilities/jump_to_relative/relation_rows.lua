local menu_schema = require("configs.hydra.atlantis.schema.menu")
local probe = require("configs.hydra.atlantis.anchor.probe")
local schema_constants = require("configs.hydra.atlantis.schema.constants")
local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")
local group_heading = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_group_heading")
local jump_row_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_labels")

local jump_cfg = menu_schema.jump

local relation_rows = {}

local function hide_child_jump_for_assignment(anchor_node_info)
  if type(anchor_node_info) ~= "table" then
    return false
  end
  local parsed = probe.parse(anchor_node_info)
  return type(parsed) == "table" and parsed.semantic_kind == schema_constants.node_kinds.assignment
end

local function item_for_relation(row, labeled)
  local L = labeled[row.relation]
  local target = L and L.target
  local quoted = L and L.quoted

  if row.relation == "parent" and target and targets.is_document_root(target) then
    local dr = jump_cfg.document_root_jump
    local phrase = type(dr) == "table" and dr.label_phrase or "To top"
    return {
      key = row.key,
      icon = type(dr) == "table" and dr.icon or "⇪",
      label = jump_row_labels.with_quoted(phrase, quoted),
      action = targets.jump_action(target),
      _atlantis_reopen_anchor_mode = true,
    }
  end

  if target and quoted then
    local item = {
      key = row.key,
      icon = row.icon,
      label = jump_row_labels.with_quoted(jump_row_labels.relation(row.relation), quoted),
      action = targets.jump_action(target),
      _atlantis_reopen_anchor_mode = true,
    }
    if row.relation == "child" then
      item._preserve_container_on_reopen = true
    end
    return item
  end

  return nil
end

function relation_rows.append(items, labeled, anchor_node_info)
  local last_group = nil
  local skip_child = hide_child_jump_for_assignment(anchor_node_info)
  for _, row in ipairs(jump_cfg.items or {}) do
    if type(row.relation) ~= "string" then
    elseif row.relation == "child" and skip_child then
    else
      if row.group ~= last_group then
        group_heading.append(items, row.group)
        last_group = row.group
      end
      local item = item_for_relation(row, labeled)
      if item then
        items[#items + 1] = item
      end
    end
  end
end

return relation_rows
