-- Core Atlantis constants used by probe, title, and schema tables
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
