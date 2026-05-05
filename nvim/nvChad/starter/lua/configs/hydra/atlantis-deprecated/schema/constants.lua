-- Core Atlantis constants used by probe, title, and schema tables
local M = {}

-- Depth delta for item reopen behaviour
M.reopen = {
  close  = -1,  -- do not reopen after action
  same   = 0,   -- reopen at same depth
  deeper = 1,   -- reopen at depth + 1 (navigate into second-class anchor)
}

-- Scope selector values for container mode
M.container_scope = {
  file          = "top_level",
  current_scope = "current_scope",
}

-- Anchor depth tiers
M.anchor_depth = {
  first_class  = 0,  -- depth <= 0: resolve first-class anchor (standard heuristic)
  second_class = 1,  -- depth >= 1: resolve second-class anchor (params, body nodes)
}

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

-- Probe id by semantic node kind for data-driven anchor parsing
M.probe_by_node_kind = {
  [M.node_kinds.declaration] = "function",
  [M.node_kinds.assignment] = "assignment",
  [M.node_kinds.identifier] = "identifier",
  [M.node_kinds.property] = "identifier",
  [M.node_kinds.statement] = "binary_expression",
}

-- Probe id by raw node type for kind-level fallback gaps
M.probe_by_node_type = {
  parameter = "parameter",
  parameters = "parameter",
  parameter_list = "parameter",
  formal_parameters = "parameter",
  parameter_declaration = "parameter",
  typed_parameter = "parameter",
  binary_expression = "binary_expression",
}

return M
