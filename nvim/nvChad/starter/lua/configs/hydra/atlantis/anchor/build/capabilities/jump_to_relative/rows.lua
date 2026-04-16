local menu_schema = require("configs.hydra.atlantis.schema.menu")
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local probe = require("configs.hydra.atlantis.anchor.probe")
local relative_jumps = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.relative_jumps")
local schema_constants = require("configs.hydra.atlantis.schema.constants")
local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")
local walker = require("configs.hydra.atlantis.outline.walker")

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

local function hide_child_jump_for_assignment(anchor_node_info)
  if type(anchor_node_info) ~= "table" then
    return false
  end
  local parsed = probe.parse(anchor_node_info)
  return type(parsed) == "table" and parsed.semantic_kind == schema_constants.node_kinds.assignment
end

local function append_relation_items(items, labeled, anchor_node_info)
  local last_group = nil
  local skip_child = hide_child_jump_for_assignment(anchor_node_info)
  for _, row in ipairs(jump_cfg.items or {}) do
    if type(row.relation) == "string" then
      if row.relation == "child" and skip_child then
        -- Child jump is misleading on assignment anchors (re-open still selects the assignment);
        -- lhs/rhs/renames live in the action column instead.
      else
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
            _atlantis_reopen_anchor_mode = true,
          }
        elseif target and quoted then
          item = {
            key = row.key,
            icon = row.icon,
            label = row_label_from_quoted(relation_phrase(row.relation), quoted),
            action = targets.jump_action(target),
            _atlantis_reopen_anchor_mode = true,
          }
        end
        if item then
          items[#items + 1] = item
        end
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
  return menu_labels.quoted_for_node(candidate.node_info, candidate.parsed)
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
      _atlantis_reopen_anchor_mode = true,
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
      _atlantis_reopen_anchor_mode = true,
    }
  end
end

local function append_navigation_items(items, anchor_node_info, menu_opts)
  append_group_heading(items, "navigation")

  local bufnr = anchor_node_info and anchor_node_info.bufnr or vim.api.nvim_get_current_buf()
  local anchor_node = anchor_node_info and anchor_node_info.node or nil
  local in_nav = type(menu_opts) == "table"
    and (menu_opts._atlantis_container_session == true or menu_opts.prefer_container == true)

  if walker.is_file_scope_anchor(anchor_node, bufnr) then
    if in_nav then
      items[#items + 1] = {
        label = jump_cfg.navigation_at_top_level_message or "🔚 Already at top level",
      }
      return
    end
    local row_H, row_h
    for _, row in ipairs(jump_cfg.items or {}) do
      if row.group == "navigation" and row.outline_scope == true then
        row_H = row
      elseif row.group == "navigation" and row.current_scope == true then
        row_h = row
      end
    end
    local label = jump_cfg.outline_scope and jump_cfg.outline_scope.label or "Top level..."
    items[#items + 1] = {
      key = row_H and row_H.key or "H",
      key_alias = row_h and row_h.key or "h",
      icon = row_H and row_H.icon,
      label = label,
      action = function() end,
      _reopen_container_mode = true,
      _atlantis_nav_mode = "top_level",
      _reopen_atlantis = -1,
    }
    return
  end

  for _, row in ipairs(jump_cfg.items or {}) do
    if row.group == "navigation" and (row.outline_scope == true or row.current_scope == true) then
      local label
      if row.outline_scope == true then
        label = jump_cfg.outline_scope and jump_cfg.outline_scope.label or "Top level..."
      else
        label = jump_cfg.current_scope and jump_cfg.current_scope.label or "Current scope..."
      end
      local nav_mode = row.outline_scope == true and "top_level" or "current_scope"
      items[#items + 1] = {
        key = row.key,
        icon = row.icon,
        label = label,
        action = function() end,
        _reopen_container_mode = true,
        _atlantis_nav_mode = nav_mode,
        _reopen_atlantis = -1,
      }
    end
  end
end

function M.build_items(anchor_node_info, find_result, menu_opts)
  local items = {}
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil
  local jump_labels = type(find_result) == "table" and find_result.jump_labels or nil

  append_navigation_items(items, anchor_node_info, menu_opts)

  local labeled = relative_jumps.labeled(anchor_node_info, jump_cfg.items)
  append_relation_items(items, labeled, anchor_node_info)
  append_context_items(items, candidates, selected_index, jump_labels)

  return items
end

return M
