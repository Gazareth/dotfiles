local menu_schema = require("configs.hydra.atlantis.schema.menu")
local probe = require("configs.hydra.atlantis.anchor.probe")
local schema_constants = require("configs.hydra.atlantis.schema.constants")
local targets = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.targets")
local row_labels = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.row_labels")
local action_layout = require("configs.hydra.atlantis.schema.actions.layout")

local navigate_cfg = menu_schema.navigate

local relation_rows = {}

local function hide_child_jump_for_assignment(anchor_node_info)
  if type(anchor_node_info) ~= "table" then
    return false
  end
  local parsed = probe.parse(anchor_node_info)
  return type(parsed) == "table" and parsed.semantic_kind == schema_constants.node_kinds.assignment
end

local function item_for_relation(row, labeled, depth, container_scope_val)
  local L = labeled[row.relation]
  local target = L and L.target
  local quoted = L and L.quoted

  if row.relation == "parent" and target and targets.is_document_root(target) then
    local dr = navigate_cfg.document_root_jump
    local phrase = type(dr) == "table" and dr.label_phrase or "To top"
    return {
      key = row.key,
      icon = type(dr) == "table" and dr.icon or "⇪",
      label = row_labels.with_quoted(phrase, quoted),
      action = targets.jump_action(target),
      reopen = { depth = depth },
    }
  end

  if target and quoted then
    local reopen_args = { depth = depth }
    if row.relation == "child" and type(container_scope_val) == "string" then
      reopen_args.container_scope = container_scope_val
    end
    return {
      key = row.key,
      icon = row.icon,
      label = row_labels.with_quoted(row_labels.relation(row.relation), quoted),
      action = targets.jump_action(target),
      reopen = reopen_args,
    }
  end

  return nil
end

function relation_rows.append(items, labeled, anchor_node_info, menu_opts)
  local depth = type(menu_opts) == "table" and (menu_opts.depth or 0) or 0
  local container_scope_val = type(menu_opts) == "table" and menu_opts.container_scope or nil
  local last_group = nil
  local skip_child = hide_child_jump_for_assignment(anchor_node_info)
  for _, row in ipairs(navigate_cfg.items or {}) do
    if type(row.relation) ~= "string" then
    elseif row.relation == "child" and skip_child then
    else
      if row.group ~= last_group then
        if row.group == "child" then
          local parsed = probe.parse(anchor_node_info)
          local kind = type(parsed) == "table" and parsed.node_kind or nil
          local title = action_layout.specific_title_for_anchor_kind(kind)
          row_labels.append_label(items, " ↥ " .. title)
        elseif row.group == "sibling" then
          row_labels.append(items, "sibling")
        end
        last_group = row.group
      end
      local item = item_for_relation(row, labeled, depth, container_scope_val)
      if item then
        items[#items + 1] = item
      end
    end
  end
end

return relation_rows
