local parse_identifier = require("configs.nui.treesitter.parsers.identifier").parse_identifier
local parse_function = require("configs.nui.treesitter.parsers.function").parse_function
local parse_binary_expression = require("configs.nui.treesitter.parsers.binary_expression").parse_binary_expression
local parse_generic = require("configs.nui.treesitter.parsers.generic").parse_generic
local node_types = require("configs.nui.treesitter.lib.constants").node_types

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

local function parse_node(node_info)
  if not node_info then
    return nil
  end

  local parser = parser_map[node_info.node_type]
  local parsed = parse_generic(node_info)

  if type(parser) == "function" then
    local ok, candidate = pcall(parser, node_info)
    if ok and type(candidate) == "table" then
      parsed = candidate
    else
      vim.notify("Treesitter parser failed for node type: " .. tostring(node_info.node_type), vim.log.levels.WARN)
    end
  end

  parsed.node_type = parsed.node_type or node_info.node_type
  parsed.text = parsed.text or node_info.text
  parsed.cursor_node_type = node_info.node_type
  return parsed
end

return parse_node
