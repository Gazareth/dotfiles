local parse_identifier = require("configs.hydra.atlantis.treesitter.probes.identifier").parse_identifier
local parse_assignment = require("configs.hydra.atlantis.treesitter.probes.assignment").parse_assignment
local parse_function = require("configs.hydra.atlantis.treesitter.probes.function").parse_function
local parse_binary_expression = require("configs.hydra.atlantis.treesitter.probes.binary_expression").parse_binary_expression
local parse_generic = require("configs.hydra.atlantis.treesitter.probes.generic").parse_generic
local treesitter_constants = require("configs.hydra.atlantis.treesitter.common.constants")
local atlantis_constants = require("configs.hydra.atlantis.registry.node_tiers")
local node_types = treesitter_constants.node_types
local node_tiers = atlantis_constants.node_tiers
local node_kinds = atlantis_constants.node_kinds
local resolve_language_mapping = require("configs.hydra.atlantis.treesitter.languages").resolve
local treesitter_config = require("configs.hydra.atlantis.treesitter.config")

-- Specialized parser map
local parser_map = {
  [node_types.identifier] = parse_identifier,
  [node_types.assignment_expression] = parse_assignment,
  [node_types.assignment_statement] = parse_assignment,
  [node_types.variable_declaration] = parse_assignment,
  [node_types.local_declaration] = parse_assignment,
  [node_types.binary_expression] = parse_binary_expression,

  [node_types.fn] = parse_function,
  [node_types.function_declaration] = parse_function,
  [node_types.function_definition] = parse_function,
  [node_types.function_expression] = parse_function,
  [node_types.method_definition] = parse_function,
  [node_types.arrow_function] = parse_function,
}

-- Safe specialized parser run
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

-- Parsed node normalization
local function normalize_parsed_result(parsed, node_info)
  local config = treesitter_config.get()
  -- Semantic resolver input
  local semantic_node_info = parsed.semantic_node_info or node_info

  parsed.node_type = parsed.node_type or node_info.node_type
  parsed.text = parsed.text or node_info.text
  parsed.cursor_node_type = node_info.node_type
  parsed.semantic = resolve_language_mapping(semantic_node_info, {
    safe_languages = config.safe_languages,
    languages = config.languages,
  })
  parsed.node_tier = parsed.semantic and parsed.semantic.node_tier or node_tiers.reef
  parsed.semantic_kind = parsed.semantic and parsed.semantic.node_kind or node_kinds.unknown
  parsed.actionable = parsed.semantic and parsed.semantic.actionable or false
  parsed.context_mode = config.context_mode or "depth_0"

  return parsed
end

-- Parser selection
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

