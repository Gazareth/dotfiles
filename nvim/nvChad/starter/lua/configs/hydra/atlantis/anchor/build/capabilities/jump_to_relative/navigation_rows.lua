local menu_schema = require("configs.hydra.atlantis.schema.menu")
local group_heading = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_group_heading")
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local probe = require("configs.hydra.atlantis.anchor.probe")
local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")
local context_rows = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.context_rows")
local walker = require("configs.hydra.atlantis.outline.walker")
local jump_row_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_labels")

local navigate_cfg = menu_schema.navigate

local navigation_rows = {}

--- @return boolean true when relation rows must be skipped (file-scope navigation strip only).
function navigation_rows.append(items, anchor_node_info, menu_opts, candidates, selected_index, jump_labels)
  group_heading.append(items, "nav_context")

  local bufnr = anchor_node_info and anchor_node_info.bufnr or vim.api.nvim_get_current_buf()
  local anchor_node = anchor_node_info and anchor_node_info.node or nil
  local in_nav = type(menu_opts) == "table"
    and (menu_opts._atlantis_container_session == true or menu_opts.prefer_container == true)

  local nc = navigate_cfg.nav_context

  if walker.is_file_scope_anchor(anchor_node, bufnr) then
    if in_nav then
      items[#items + 1] = {
        label = nc.already_at_top_level,
      }
      return true
    end
    local row_H, row_h
    for _, row in ipairs(navigate_cfg.items or {}) do
      if row.group == "nav_context" and row.outline_scope == true then
        row_H = row
      elseif row.group == "nav_context" and row.current_scope == true then
        row_h = row
      end
    end
    local label = nc.to_top_level
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
    return true
  end

  for _, row in ipairs(navigate_cfg.items or {}) do
    if row.group == "nav_context" and (row.outline_scope == true or row.current_scope == true) then
      local label
      if row.outline_scope == true then
        label = nc.to_top_level
      else
        label = nc.current_scope
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

  local next_target = targets.resolve_next_highest_anchor(anchor_node_info)
  if next_target then
    local parsed = probe.parse(next_target)
    local quoted = menu_labels.quoted_target(next_target, parsed)
    local nh = navigate_cfg.next_highest or {}
    local phrase = type(nh.label_phrase) == "string" and nh.label_phrase or "To next highest"
    items[#items + 1] = {
      key = nh.key or "J",
      icon = nh.icon,
      label = jump_row_labels.with_quoted(phrase, quoted),
      action = targets.jump_action(next_target),
      _atlantis_reopen_anchor_mode = true,
    }
  end

  context_rows.append_stack_neighbors(items, candidates or {}, selected_index, jump_labels)
  return false
end

return navigation_rows
