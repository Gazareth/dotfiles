local parse_identifier = require("configs.hydra.atlantis.anchor.probe.node_kinds.identifier").parse_identifier
local parse_assignment = require("configs.hydra.atlantis.anchor.probe.node_kinds.assignment").parse_assignment
local parse_function = require("configs.hydra.atlantis.anchor.probe.node_kinds.function").parse_function
local parse_parameter = require("configs.hydra.atlantis.anchor.probe.node_kinds.parameter").parse_parameter
local parse_binary_expression = require("configs.hydra.atlantis.anchor.probe.node_kinds.binary_expression").parse_binary_expression
local parse_generic = require("configs.hydra.atlantis.anchor.probe.node_kinds.generic").parse_generic
local kinds = require("configs.hydra.atlantis.schema.constants")
local resolve_language_mapping = require("configs.hydra.atlantis.anchor.languages").resolve
local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")

local node_tiers = kinds.node_tiers
local node_kinds = kinds.node_kinds

local M = {}

-- Probe parser callbacks by schema probe id
local parser_by_probe_id = {
	identifier = parse_identifier,
	assignment = parse_assignment,
	["function"] = parse_function,
	parameter = parse_parameter,
	binary_expression = parse_binary_expression,
	generic = parse_generic,
}

-- Resolve parser id from semantic kind first, then raw node type fallback
local function resolve_probe_id(node_info, semantic)
	local semantic_kind = type(semantic) == "table" and semantic.node_kind or nil
	local probe_id = semantic_kind and kinds.probe_by_node_kind[semantic_kind] or nil
	if type(probe_id) == "string" and probe_id ~= "" then
		return probe_id
	end

	local node_type = type(node_info) == "table" and node_info.node_type or nil
	probe_id = node_type and kinds.probe_by_node_type[node_type] or nil
	if type(probe_id) == "string" and probe_id ~= "" then
		return probe_id
	end

	return "generic"
end

-- Run parser callback safely and return nil when parser fails
local function parse_with_specialized_parser(parser, node_info)
	if type(parser) ~= "function" then
		return nil
	end

	local ok, candidate = pcall(parser, node_info)
	if ok and type(candidate) == "table" then
		return candidate
	end

	vim.notify("Probe parser failed for node type: " .. tostring(node_info.node_type), vim.log.levels.WARN)
	return nil
end

-- Build semantic payload once so parser selection stays data-driven
local function resolve_semantic(node_info)
	local config = treesitter_config.get()
	return resolve_language_mapping(node_info, {
		safe_languages = config.safe_languages,
		languages = config.languages,
	}), config
end

-- Normalize parser output into a stable anchor payload shape
local function normalize_parsed_result(parsed, node_info, semantic, config)
	parsed.node_type = parsed.node_type or node_info.node_type
	parsed.text = parsed.text or node_info.text
	parsed.cursor_node_type = node_info.node_type
	parsed.semantic = semantic
	parsed.node_tier = semantic and semantic.node_tier or node_tiers.reef
	parsed.semantic_kind = semantic and semantic.node_kind or node_kinds.unknown
	parsed.node_kind = parsed.node_kind or parsed.semantic_kind
	parsed.actionable = semantic and semantic.actionable or false
	parsed.depth = config.depth or 0

	return parsed
end

-- Parse node by semantic kind schema mapping and return normalized payload.
-- opts.semantic + opts.config: skip languages.resolve when caller already resolved (e.g. anchor_actionable.check).
function M.parse(node_info, opts)
	if not node_info then
		return nil
	end

	opts = type(opts) == "table" and opts or {}
	local semantic, config
	if type(opts.semantic) == "table" then
		semantic = opts.semantic
		config = type(opts.config) == "table" and opts.config or treesitter_config.get()
	else
		semantic, config = resolve_semantic(node_info)
	end

	local probe_id = resolve_probe_id(node_info, semantic)
	local parser = parser_by_probe_id[probe_id]

	local parsed = parse_generic(node_info)
	local candidate = parse_with_specialized_parser(parser, node_info)
	if candidate then
		parsed = candidate
	end

	return normalize_parsed_result(parsed, node_info, semantic, config)
end

setmetatable(M, {
	-- Keep callable module behavior for existing call sites
	__call = function(_, node_info, opts)
		return M.parse(node_info, opts)
	end,
})

return M
