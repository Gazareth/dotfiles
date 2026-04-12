local schema_constants = require("configs.hydra.atlantis.schema.constants")
local nk = schema_constants.node_kinds

local M = {}

M.title = " 󰷏 Jump to top-level entity"

--- Second-level list Hydra (one row per node); title reads "Go to <kind heading>".
M.picker_title_prefix = "Go to"
M.picker_section_title = ""

--- Hint column title for the main outline.
M.section_title = ""

--- Extra spaces on each side of the floating hint body (main file nav menu only).
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
