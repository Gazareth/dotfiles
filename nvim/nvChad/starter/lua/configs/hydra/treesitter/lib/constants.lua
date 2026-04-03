local M = {}

M.node_types = {
  identifier = "identifier",
  binary_expression = "binary_expression",
  assignment_expression = "assignment_expression",
  assignment_statement = "assignment_statement",
  variable_declaration = "variable_declaration",
  local_declaration = "local_declaration",
  pair = "pair",
  field = "field",
  property = "property",
  property_identifier = "property_identifier",
  object = "object",
  parameter = "parameter",
  parameter_declaration = "parameter_declaration",
  typed_parameter = "typed_parameter",
  parameters = "parameters",
  parameter_list = "parameter_list",
  formal_parameters = "formal_parameters",
  arguments = "arguments",
  method_definition = "method_definition",
  function_declaration = "function_declaration",
  function_definition = "function_definition",
  function_expression = "function_expression",
  arrow_function = "arrow_function",
  ["function"] = "function",
}

M.supported_nodes = {
  generic = "generic",
  identifier = "identifier",
  binary_expression = "binary_expression",
  ["function"] = "function",
}

M.roles = {
  identifier = "identifier",
  field = "field",
  parameter = "parameter",
  binding = "binding",
  method = "method",
  ["function"] = "function",
}

M.identifier_role_parent_types = {
  field = {
    [M.node_types.field] = true,
    [M.node_types.pair] = true,
    [M.node_types.property] = true,
    [M.node_types.property_identifier] = true,
    [M.node_types.object] = true,
  },
  parameter = {
    [M.node_types.parameter] = true,
    [M.node_types.parameters] = true,
    [M.node_types.parameter_list] = true,
    [M.node_types.formal_parameters] = true,
    [M.node_types.arguments] = true,
  },
  binding = {
    [M.node_types.variable_declaration] = true,
    [M.node_types.local_declaration] = true,
    [M.node_types.assignment_statement] = true,
    [M.node_types.assignment_expression] = true,
  },
}

M.parameter_container_types = {
  [M.node_types.parameters] = true,
  [M.node_types.parameter_list] = true,
  [M.node_types.formal_parameters] = true,
}

M.method_receiver_names = {
  self = true,
  this = true,
}

return M
