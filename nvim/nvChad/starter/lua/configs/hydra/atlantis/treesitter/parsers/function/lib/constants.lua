local M = {}
local node_types = require("configs.hydra.atlantis.treesitter.lib.constants").node_types

M.function_like_types = {
  [node_types["function"]] = true,
  [node_types.function_declaration] = true,
  [node_types.function_definition] = true,
  [node_types.function_expression] = true,
  [node_types.method_definition] = true,
  [node_types.arrow_function] = true,
}

M.assignment_types = {
  [node_types.assignment_statement] = true,
  [node_types.assignment_expression] = true,
  [node_types.variable_declaration] = true,
  [node_types.local_declaration] = true,
}

M.table_assignment_types = {
  [node_types.pair] = true,
  [node_types.field] = true,
}

M.parameter_types = {
  [node_types.parameter] = true,
  [node_types.parameter_declaration] = true,
  [node_types.typed_parameter] = true,
  [node_types.identifier] = true,
}

return M

