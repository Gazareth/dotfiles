local parse_identifier = require("configs.hydra.treesitter.parsers.identifier").parse_identifier
local parse_function = require("configs.hydra.treesitter.parsers.function").parse_function
local parse_binary_expression = require("configs.hydra.treesitter.parsers.binary_expression").parse_binary_expression
local parse_generic = require("configs.hydra.treesitter.parsers.generic").parse_generic
local node_types = require("configs.hydra.treesitter.lib.constants").node_types

local parser_map = {
  [node_types.identifier] = parse_identifier,
  [node_types.binary_expression] = parse_binary_expression,

  [node_types["function"]] = parse_function,
  [node_types.function_declaration] = parse_function,
  [node_types.function_definition] = parse_function,
  [node_types.function_expression] = parse_function,
  [node_types.method_definition] = parse_function,
  [node_types.arrow_function] = parse_function,
}

-- Run the selected parser safely and return nil if it fails.
local function parse_with_specialized_parser(parser, node_info)
  if type(parser) ~= "function" then
    return nil
  end

  local ok, candidate = pcall(parser, node_info)
  if ok and type(candidate) == "table" then
    return candidate
  end

  vim.notify("Treesitter parser failed for node type: " .. tostring(node_info.node_type), vim.log.levels.WARN)
  return nil
end

-- Fill in any common fields that a parser might have left out.
local function normalize_parsed_result(parsed, node_info)
  parsed.node_type = parsed.node_type or node_info.node_type
  parsed.text = parsed.text or node_info.text
  parsed.cursor_node_type = node_info.node_type
  return parsed
end

-- Pick the right parser for the current node or fall back to the generic parser.
local function parse_node(node_info)
  if not node_info then
    return nil
  end

  local parser = parser_map[node_info.node_type]
  local parsed = parse_generic(node_info)
  local candidate = parse_with_specialized_parser(parser, node_info)
  if candidate then
    parsed = candidate
  end

  return normalize_parsed_result(parsed, node_info)
end

return parse_node

