local schema_constants = require("configs.hydra.atlantis-deprecated.schema.constants")
local container_scope = schema_constants.container_scope

local menu_schema = require("configs.hydra.atlantis-deprecated.schema.menu")
local row_labels = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.row_labels")
local menu_labels = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.labels")
local probe = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe")
local targets = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.targets")
local context_rows = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.context_rows")
local walker = require("configs.hydra.atlantis-deprecated.prepare.anchor_container.scope_resolver")
local title_builder = require("configs.hydra.atlantis-deprecated.menu.components.title.builder")

local navigate_cfg = menu_schema.navigate

local navigation_rows = {}

local function make_title_override(anchor_node_info)
  local parsed = probe.parse(anchor_node_info)
  return title_builder.build_from_parsed(anchor_node_info, parsed)
end

-- Walk up via resolve_next_highest_anchor until there is no higher anchor.
-- Returns the topmost ancestor node_info, or nil for truly top-level anchors.
local function find_topmost_anchor(anchor_node_info)
  local current = anchor_node_info
  local topmost = nil
  while true do
    local next = targets.resolve_next_highest_anchor(current)
    if not next then break end
    topmost = next
    current = next
  end
  return topmost
end

--- @return boolean true when relation rows must be skipped.
function navigation_rows.append(items, anchor_node_info, menu_opts, candidates, selected_index, jump_labels)
  row_labels.append(items, "nav_context")

  local bufnr = anchor_node_info and anchor_node_info.bufnr or vim.api.nvim_get_current_buf()
  local anchor_node = anchor_node_info and anchor_node_info.node or nil
  local depth = type(menu_opts) == "table" and (menu_opts.depth or 0) or 0
  local in_nav = type(menu_opts) == "table" and type(menu_opts.container_scope) == "string"

  local nc = navigate_cfg.nav_context

  -- Container mode at file scope: already at the top, nothing more to offer.
  if walker.is_file_scope_anchor(anchor_node, bufnr) and in_nav then
    items[#items + 1] = {
      label = nc.already_at_top_level,
    }
    return true
  end

  local title_override_cache = nil
  local function get_title_override()
    if not title_override_cache then
      title_override_cache = make_title_override(anchor_node_info)
    end
    return title_override_cache
  end

  local topmost = find_topmost_anchor(anchor_node_info)
  local to_top_level_action = targets.jump_action(topmost)
  local next_target = targets.resolve_next_highest_anchor(anchor_node_info)

  if not next_target then
    -- We are TRULY at the top level (no higher standard anchor)
    -- H and h both navigate to file-root container mode — alias them together.
    local outline_row
    for _, row in ipairs(navigate_cfg.items or {}) do
      if row.group == "nav_context" and row.outline_scope == true then
        outline_row = row
      end
    end
    items[#items + 1] = {
      key = outline_row and outline_row.key or "H",
      key_alias = "h",
      icon = outline_row and outline_row.icon,
      label = nc.to_top_level,
      action = to_top_level_action,
      reopen = {
        depth = -1,
        container_scope = container_scope.file,
        title_override = get_title_override(),
      },
    }
  else
    -- Nested anchor: H (to file root) and l (to current scope) are distinct.
    local outline_row, scope_row
    for _, row in ipairs(navigate_cfg.items or {}) do
      if row.group == "nav_context" then
        if row.outline_scope == true then
          outline_row = row
        elseif row.current_scope == true then
          scope_row = row
        end
      end
    end

    -- 1. Top
    if outline_row then
      items[#items + 1] = {
        key = outline_row.key,
        icon = outline_row.icon,
        label = nc.to_top_level,
        action = to_top_level_action,
        reopen = {
          depth = -1,
          container_scope = container_scope.file,
          title_override = get_title_override(),
        },
      }
    end

    -- 2. Next highest
    local parsed = probe.parse(next_target)
    local quoted = menu_labels.quoted_target(next_target, parsed)
    local nh = navigate_cfg.next_highest or {}
    local phrase = type(nh.label_phrase) == "string" and nh.label_phrase or "To next highest"
    local nh_reopen = { depth = 0 }
    if type(next_target) == "table" and next_target.node then
      nh_reopen.anchor_pos = { bufnr = next_target.bufnr or 0, row = (next_target.start_row or 0) + 1, col = next_target.start_col or 0 }
    end
    items[#items + 1] = {
      key = nh.key or "h",
      icon = nh.icon,
      label = row_labels.with_quoted(phrase, quoted),
      action = targets.jump_action(next_target),
      reopen = nh_reopen,
    }

    -- 3. Current
    if scope_row then
      items[#items + 1] = {
        key = scope_row.key,
        icon = scope_row.icon,
        label = nc.current_scope,
        action = function() end,
        reopen = {
          depth = depth,
          container_scope = container_scope.current_scope,
        },
      }
    end
  end

  context_rows.append_stack_neighbors(items, candidates or {}, selected_index, jump_labels, menu_opts)
  return false
end

return navigation_rows
