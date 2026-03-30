local identifier_parser = require("configs.nui.treesitter.parsers.identifier")
local function_parser = require("configs.nui.treesitter.parsers.function")
local binary_expression_parser = require("configs.nui.treesitter.parsers.binary_expression")
local lib = require("configs.nui.treesitter.lib")
local node_types = require("configs.nui.treesitter.lib.constants").node_types
local supported_nodes = require("configs.nui.treesitter.lib.constants").supported_nodes

local parser_map = {
  [node_types.identifier] = identifier_parser.parse_identifier,
  [node_types.binary_expression] = binary_expression_parser.parse_binary_expression,

  [node_types["function"]] = function_parser.parse_function,
  [node_types.function_declaration] = function_parser.parse_function,
  [node_types.function_definition] = function_parser.parse_function,
  [node_types.function_expression] = function_parser.parse_function,
  [node_types.method_definition] = function_parser.parse_function,
  [node_types.arrow_function] = function_parser.parse_function,
}

local function parse_node(node_info)
  if not node_info then
    return nil
  end

  local parser = parser_map[node_info.node_type]
  if type(parser) ~= "function" then
    return {
      node_kind = supported_nodes.generic,
      role = node_info.node_type,
      display_name = node_info.node_type,
      summary = {},
    }
  end

  local ok, parsed = pcall(parser, node_info)
  if not ok or type(parsed) ~= "table" then
    vim.notify("Treesitter parser failed for node type: " .. tostring(node_info.node_type), vim.log.levels.WARN)
    return {
      node_kind = supported_nodes.generic,
      role = node_info.node_type,
      display_name = node_info.node_type,
      summary = {},
    }
  end

  parsed.node_type = node_info.node_type
  parsed.text = node_info.text
  return parsed
end

return parse_node