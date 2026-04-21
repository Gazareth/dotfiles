local schema_constants = require("configs.hydra.atlantis.schema.constants")
local container_scope = schema_constants.container_scope

local menu_schema = require("configs.hydra.atlantis.schema.menu")
local row_labels = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.row_labels")
local menu_labels = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.labels")
local probe = require("configs.hydra.atlantis.anchor.probe")
local targets = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.targets")
local context_rows = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.context_rows")
local walker = require("configs.hydra.atlantis.container.scope_resolver")
local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")

local navigate_cfg = menu_schema.navigate

local navigation_rows = {}

--- @return boolean true when relation rows must be skipped (file-scope navigation strip only).
function navigation_rows.append(items, anchor_node_info, menu_opts, candidates, selected_index, jump_labels)
  row_labels.append(items, "nav_context")

  local bufnr = anchor_node_info and anchor_node_info.bufnr or vim.api.nvim_get_current_buf()
  local anchor_node = anchor_node_info and anchor_node_info.node or nil
  local depth = type(menu_opts) == "table" and (menu_opts.depth or 0) or 0
  local in_nav = type(menu_opts) == "table" and type(menu_opts.container_scope) == "string"

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
    local parsed = probe.parse(anchor_node_info)
    local title_override = title_builder.build_from_parsed(anchor_node_info, parsed)
    items[#items + 1] = {
      key = row_H and row_H.key or "H",
      key_alias = row_h and row_h.key or "h",
      icon = row_H and row_H.icon,
      label = nc.to_top_level,
      action = function() end,
      reopen = {
        depth = depth,
        container_scope = container_scope.file,
        title_override = title_override,
      },
    }
    return true
  end

  for _, row in ipairs(navigate_cfg.items or {}) do
    if row.group == "nav_context" and (row.outline_scope == true or row.current_scope == true) then
      local label
      local item_reopen
      if row.outline_scope == true then
        label = nc.to_top_level
        local parsed = probe.parse(anchor_node_info)
        local title_override = title_builder.build_from_parsed(anchor_node_info, parsed)
        item_reopen = {
          depth = depth,
          container_scope = container_scope.file,
          title_override = title_override,
        }
      else
        label = nc.current_scope
        item_reopen = {
          depth = depth,
          container_scope = container_scope.current_scope,
        }
      end
      items[#items + 1] = {
        key = row.key,
        icon = row.icon,
        label = label,
        action = function() end,
        reopen = item_reopen,
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
      label = row_labels.with_quoted(phrase, quoted),
      action = targets.jump_action(next_target),
      reopen = { depth = depth },
    }
  end

  context_rows.append_stack_neighbors(items, candidates or {}, selected_index, jump_labels, menu_opts)
  return false
end

return navigation_rows
