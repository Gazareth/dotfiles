local M = {}

-- Semantic tier constants used for anchor depth scoring
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

-- Semantic kind constants used for titles and mappings
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

-- Canonical action ids used by menu row filtering
M.action_ids = {
  inspect = "inspect",
  jump = "jump",
  jump_parent = "jump_parent",
  select = "select",
  change = "change",
  rename = "rename",
  yank = "yank",
  delete = "delete",
  view_call_hierarchy = "view_call_hierarchy",
}

return M
