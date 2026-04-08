local M = {}

-- Atlantis node tiers
M.node_tiers = {
  colony = "colony",
  settlement = "settlement",
  grove = "grove",
  cluster = "cluster",
  habitat = "habitat",
  chambers = "chambers",
  coral = "coral",
  reef = "reef",
}

-- Atlantis node kinds
M.node_kinds = {
  unknown = "unknown",
  declaration = "declaration",
  collection = "collection",
  control_frame = "control_frame",
  statement = "statement",
  assignment = "assignment",
  call = "call",
  identifier = "identifier",
  property = "property",
  keyword = "keyword",
  operator = "operator",
  delimiter = "delimiter",
  whitespace = "whitespace",
  comment = "comment",
  string = "string",
}

-- Atlantis action ids
M.action_ids = {
  inspect = "inspect",
  jump = "jump",
  jump_parent = "jump_parent",
  select = "select",
  change = "change",
  change_name = "change_name",
  yank = "yank",
  delete = "delete",
  view_call_hierarchy = "view_call_hierarchy",
}

return M
