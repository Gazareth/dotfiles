local column_titles = require("configs.hydra.atlantis-deprecated.menu.column_titles")
local schema_constants = require("configs.hydra.atlantis-deprecated.schema.constants")
local nk = schema_constants.node_kinds

local M = {}

M.title = column_titles.outline_window()

M.picker_title_prefix = "Go to"
M.picker_section_title = ""

M.section_title = ""

M.hint_padding_left = 1
M.hint_padding_right = 2

M.kind_order = {
  nk.declaration,
  nk.assignment,
  nk.control_frame,
  nk.collection,
  nk.call,
  nk.property,
  nk.statement,
  nk.keyword,
  nk.operator,
  nk.unknown,
}

M.kind_heading = {
  [nk.declaration] = "Declarations",
  [nk.assignment] = "Assignments",
  [nk.control_frame] = "Control flow",
  [nk.collection] = "Collections",
  [nk.call] = "Calls",
  [nk.property] = "Properties",
  [nk.statement] = "Statements",
  [nk.keyword] = "Keywords",
  [nk.operator] = "Operators",
  [nk.unknown] = "Other",
}

M.text = {
  to = "To",
  to_next = "To next",
  pick = M.picker_title_prefix,
}

return M
