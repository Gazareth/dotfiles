local atlantis_constants = require("configs.hydra.atlantis.registry.node_tiers")
local node_tiers = atlantis_constants.node_tiers
local node_kinds = atlantis_constants.node_kinds

local M = {}

-- Detect language from node (then buffer - as a fallback)
local function detect_language(node_info)
  if node_info and node_info.node then
    local ok, lang = pcall(function()
      return node_info.node:lang()
    end)

    if ok and type(lang) == "string" and lang ~= "" then
      return lang
    end
  end

  if node_info and node_info.bufnr then
    local filetype = vim.bo[node_info.bufnr].filetype
    if type(filetype) == "string" and filetype ~= "" then
      return filetype
    end
  end

  return vim.bo.filetype
end

-- Resolve whether raw syntax node is named for diagnostics
local function get_node_named_flag(node_info)
  if not node_info or not node_info.node then
    return false
  end

  local ok, named = pcall(function()
    return node_info.node:named()
  end)

  return ok and named == true
end

-- Build semantic payload for unsupported raw node type
local function build_unknown_result(language, mapping_source, node_info)
  return {
    status = "unknown-node",
    language = language,
    mapping_source = mapping_source,
    raw_node_type = node_info.node_type,
    parent_node_type = node_info.parent_type,
    cursor = node_info.cursor,
    named = get_node_named_flag(node_info),
    node_tier = node_tiers.reef,
    node_kind = node_kinds.unknown,
    actionable = false,
  }
end

-- Build semantic payload for supported mapped node type
local function build_supported_result(language, mapping_source, node_info, mapping)
  local node_tier = mapping.node_tier or node_tiers.reef
  local node_kind = mapping.node_kind or node_kinds.unknown

  return {
    status = "ok",
    language = language,
    mapping_source = mapping_source,
    raw_node_type = node_info.node_type,
    parent_node_type = node_info.parent_type,
    cursor = node_info.cursor,
    named = get_node_named_flag(node_info),
    node_tier = node_tier,
    node_kind = node_kind,
    actionable = mapping.actionable == true,
  }
end

-- Build semantic payload when language mappings are disabled
local function build_unsupported_result(language, node_info)
  return {
    status = "unsupported-language",
    language = language,
    raw_node_type = node_info.node_type,
    parent_node_type = node_info.parent_type,
    cursor = node_info.cursor,
    named = get_node_named_flag(node_info),
    node_tier = node_tiers.reef,
    node_kind = node_kinds.unknown,
    actionable = false,
    mapping_source = "unsupported",
  }
end

-- Merge mapping layers and resolve semantic node metadata
function M.resolve(node_info, opts)
  opts = opts or {}

  local safe_languages = opts.safe_languages == true
  local user_languages = opts.user_languages or {}
  local base_languages = opts.base_languages or {}
  local core = opts.core or {}
  local common = opts.common or {}
  local language = opts.language or detect_language(node_info)
  local language_base = base_languages[language]

  if safe_languages and not language_base and not user_languages[language] then
    return build_unsupported_result(language, node_info)
  end

  -- Layer precedence core -> common -> language base -> user overrides
  local merged = vim.tbl_deep_extend("force", vim.deepcopy(core), common, language_base or {}, user_languages[language] or {})
  local mapping = (merged.mappings or {})[node_info.node_type]

  if not mapping then
    return build_unknown_result(language, language_base and "language+common+core" or "common+core", node_info)
  end

  return build_supported_result(language, language_base and "language+common+core" or "common+core", node_info, mapping)
end

return M
