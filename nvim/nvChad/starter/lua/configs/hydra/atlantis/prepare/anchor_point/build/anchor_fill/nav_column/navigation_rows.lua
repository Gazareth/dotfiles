local schema_constants = require("configs.hydra.atlantis.schema.constants")
local container_scope = schema_constants.container_scope

local menu_schema = require("configs.hydra.atlantis.schema.menu")
local row_labels = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.row_labels")
local menu_labels = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels")
local probe = require("configs.hydra.atlantis.prepare.anchor_point.probe")
local targets = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.targets")
local context_rows = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.context_rows")
local walker = require("configs.hydra.atlantis.prepare.anchor_container.scope_resolver")
local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")

local navigate_cfg = menu_schema.navigate

local navigation_rows = {}

local function make_title_override(anchor_node_info)
  local parsed = probe.parse(anchor_node_info)
  return title_builder.build_from_parsed(anchor_node_info, parsed)
end

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
    local outline_row, scope_row
    for _, row in ipairs(navigate_cfg.items or {}) do
      if row.group == "nav_context" and row.outline_scope == true then
        outline_row = row
      elseif row.group == "nav_context" and row.current_scope == true then
        scope_row = row
      end
    end
    items[#items + 1] = {
      key = outline_row and outline_row.key or "H",
      key_alias = scope_row and scope_row.key or "h",
      icon = outline_row and outline_row.icon,
      label = nc.to_top_level,
      action = function() end,
      reopen = {
        depth = depth,
        container_scope = container_scope.file,
        title_override = make_title_override(anchor_node_info),
      },
    }
    return true
  end

  local title_override_cache = nil
  for _, row in ipairs(navigate_cfg.items or {}) do
    if row.group == "nav_context" and (row.outline_scope == true or row.current_scope == true) then
      local label
      local item_reopen
      if row.outline_scope == true then
        label = nc.to_top_level
        if not title_override_cache then
          title_override_cache = make_title_override(anchor_node_info)
        end
        item_reopen = {
          depth = depth,
          container_scope = container_scope.file,
          title_override = title_override_cache,
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
