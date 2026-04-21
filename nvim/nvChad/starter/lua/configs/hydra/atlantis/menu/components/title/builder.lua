-- Assembles final title strings from badge, name, and metric parts
local treesitter_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants")
local node_kinds_const = require("configs.hydra.atlantis.schema.constants").node_kinds
local constants = require("configs.hydra.atlantis.menu.components.title.constants")
local extract = require("configs.hydra.atlantis.menu.components.title.extract")

local supported_fn = treesitter_constants.supported_nodes.fn
local roles = treesitter_constants.roles

local M = {}

local function function_scope_label(parsed, raw_text)
  if parsed and parsed.role == roles.method then
    return "method"
  end
  if type(raw_text) == "string" and vim.trim(raw_text):match("^local%s") then
    return "local"
  end
  return "global"
end

-- Format metric strings for title suffix display
local function format_metrics(list)
  if type(list) ~= "table" or #list == 0 then
    return ""
  end

  local parts = {}
  for _, metric in ipairs(list) do
    if type(metric) == "string" and metric ~= "" then
      parts[#parts + 1] = metric
    end
  end

  if #parts == 0 then
    return ""
  end

  return "{ " .. table.concat(parts, ", ") .. " }"
end

-- Count lines spanned by node for title metrics
local function count_lines(node_info, raw_text)
  if node_info and node_info.start_row and node_info.end_row then
    return (node_info.end_row - node_info.start_row) + 1
  end

  if not raw_text then
    return 1
  end

  local count = 0
  for _ in raw_text:gmatch("[^\n]+") do
    count = count + 1
  end
  return math.max(count, 1)
end

-- Build final title string with label, icon, name, and metrics
function M.build(opts)
  local label = opts.label or constants.resolve_label(opts.semantic_kind, opts.node_type)
  local icon = opts.icon or constants.resolve_icon(opts.semantic_kind, opts.node_type)

  local bracket = icon ~= "" and ("[" .. label .. " " .. icon .. "]") or ("[" .. label .. "]")
  local name = (type(opts.name) == "string" and opts.name ~= "") and opts.name or nil
  local metrics_str = format_metrics(opts.metrics or {})

  local result = bracket
  if name then
    result = result .. " " .. name
  end
  if metrics_str ~= "" then
    result = result .. " " .. metrics_str
  end

  return result
end

-- Strategy functions: each receives (node_info, parsed, raw_text, line_count) and
-- returns { name, metrics }.

local function strategy_comment(_node_info, _parsed, raw_text, _line_count)
  local comment_name, char_count = extract.extract_comment_name(raw_text)
  local metrics = {}
  if char_count and char_count > 0 then
    metrics = { tostring(char_count) .. " characters" }
  end
  return { name = comment_name, metrics = metrics }
end

local function strategy_for_loop(_node_info, _parsed, raw_text, line_count)
  local metrics = {}
  if line_count > 1 then
    metrics = { line_count .. " lines" }
  end
  return { name = extract.extract_for_name(raw_text), metrics = metrics }
end

local function strategy_if_stmt(_node_info, _parsed, raw_text, line_count)
  local metrics = {}
  if line_count > 1 then
    metrics = { line_count .. " lines" }
  end
  return { name = extract.extract_if_name(raw_text), metrics = metrics }
end

local function strategy_loop_generic(_node_info, _parsed, raw_text, line_count)
  local first_line = raw_text:match("^([^\n]+)") or raw_text
  local metrics = {}
  if line_count > 1 then
    metrics = { line_count .. " lines" }
  end
  return { name = extract.truncate(vim.trim(first_line), 50), metrics = metrics }
end

local function strategy_assignment(_node_info, _parsed, raw_text, _line_count)
  local metrics = {}
  if raw_text:match("^%s*local%s") then
    metrics = { "local" }
  end
  return { name = extract.extract_assignment_name(raw_text), metrics = metrics }
end

local function strategy_fn(node_info, parsed, raw_text, _line_count)
  local name = type(parsed.function_name) == "string" and parsed.function_name or nil
  local m = type(parsed.metrics) == "table" and parsed.metrics or {}
  local pc = type(m.parameter_count) == "number" and m.parameter_count or 0
  local lines_n = type(m.line_span) == "number" and m.line_span or count_lines(node_info, raw_text)
  local param_phrase = pc == 1 and "1 parameter" or (tostring(pc) .. " parameters")
  local line_phrase = lines_n == 1 and "1 line" or (tostring(lines_n) .. " lines")
  return {
    name = name,
    metrics = { function_scope_label(parsed, raw_text), param_phrase, line_phrase },
  }
end

local function strategy_fallback(_node_info, _parsed, raw_text, line_count)
  local first_line = raw_text:match("^([^\n]+)") or raw_text
  local metrics = {}
  if line_count > 1 then
    metrics = { line_count .. " lines" }
  end
  return { name = extract.truncate(vim.trim(first_line), 50), metrics = metrics }
end

-- Dispatch tables keyed by node_type and semantic_kind.
-- semantic_kind table is checked first (more specific).
-- fn is checked separately because it guards on parsed.node_kind, not semantic_kind.
local by_node_type = {
  for_statement    = strategy_for_loop,
  for_in_statement = strategy_for_loop,
  if_statement     = strategy_if_stmt,
  while_statement  = strategy_loop_generic,
  repeat_statement = strategy_loop_generic,
}

local by_semantic_kind = {
  [node_kinds_const.comment]    = strategy_comment,
  [node_kinds_const.assignment] = strategy_assignment,
}

-- Build node title text from parsed semantic data
function M.build_from_parsed(node_info, parsed)
  local semantic_kind = (parsed and parsed.semantic_kind) or ""
  local node_type = (parsed and parsed.node_type)
    or (node_info and node_info.node_type)
    or ""
  local raw_text = (parsed and parsed.text) or (node_info and node_info.text) or ""
  local line_count = count_lines(node_info, raw_text)

  local strat
  if parsed and parsed.node_kind == supported_fn and type(parsed.function_name) == "string" then
    strat = strategy_fn
  elseif by_semantic_kind[semantic_kind] then
    strat = by_semantic_kind[semantic_kind]
  else
    strat = by_node_type[node_type] or strategy_fallback
  end

  local result = strat(node_info, parsed, raw_text, line_count)

  return M.build({
    semantic_kind = semantic_kind,
    node_type = node_type,
    name = result.name,
    metrics = result.metrics,
  })
end

return M
