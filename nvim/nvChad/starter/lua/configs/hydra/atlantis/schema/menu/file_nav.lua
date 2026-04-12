local schema_constants = require("configs.hydra.atlantis.schema.constants")
local nk = schema_constants.node_kinds

local M = {}

M.title = " 󰷏 File nav"

--- Hint column title; kind groups use separator rows with counts.
M.section_title = ""

--- Display order for kind sections (empty kinds omitted).
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

--- Plain group names (no Atlantis tier vocabulary).
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
}

return M
