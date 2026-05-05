local menu_labels = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.labels")
local schema = require("configs.hydra.atlantis-deprecated.schema.menu.outline")
local title_const = require("configs.hydra.atlantis-deprecated.menu.components.title.constants")

local M = {}

function M.kind_bracket(e)
  if type(e) ~= "table" or type(e.node_info) ~= "table" then
    return "?"
  end
  local kind = type(e.semantic) == "table" and e.semantic.node_kind or nil
  return title_const.resolve_label(kind, e.node_info.node_type)
end

function M.row_single(e)
  local bracket = M.kind_bracket(e)
  local name = menu_labels.display_name_for_node(e.node_info, e.parsed)
  local line = (type(e.row) == "number" and e.row or 0) + 1
  return string.format("%s [%s] %s:%d", schema.text.to, bracket, name, line)
end

function M.row_next(e)
  local bracket = M.kind_bracket(e)
  local name = menu_labels.display_name_for_node(e.node_info, e.parsed)
  local line = (type(e.row) == "number" and e.row or 0) + 1
  return string.format("%s [%s] %s:%d", schema.text.to_next, bracket, name, line)
end

function M.pick_row(kind_id)
  local title = schema.kind_heading[kind_id]
  if type(title) == "string" and title ~= "" then
    return string.format("%s %s...", schema.text.pick, title)
  end
  return string.format("%s ...", schema.text.pick)
end

return M
