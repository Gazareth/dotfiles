local menu_schema = require("configs.hydra.atlantis.schema.menu")
local group_heading = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_group_heading")
local walker = require("configs.hydra.atlantis.outline.walker")

local jump_cfg = menu_schema.jump

local navigation_rows = {}

--- @return boolean true when relation/context rows must be skipped (file-scope navigation strip only).
function navigation_rows.append(items, anchor_node_info, menu_opts)
  group_heading.append(items, "navigation")

  local bufnr = anchor_node_info and anchor_node_info.bufnr or vim.api.nvim_get_current_buf()
  local anchor_node = anchor_node_info and anchor_node_info.node or nil
  local in_nav = type(menu_opts) == "table"
    and (menu_opts._atlantis_container_session == true or menu_opts.prefer_container == true)

  if walker.is_file_scope_anchor(anchor_node, bufnr) then
    if in_nav then
      items[#items + 1] = {
        label = jump_cfg.navigation_at_top_level_message or "🔚 Already at top level",
      }
      return true
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
    return true
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
  return false
end

return navigation_rows
