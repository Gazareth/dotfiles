-- Assembles final title strings from badge, name, and metric parts
local node_kinds_const = require("configs.hydra.atlantis.registry.constants").node_kinds
local constants = require("configs.hydra.atlantis.menu.components.title.constants")
local extract = require("configs.hydra.atlantis.menu.components.title.extract")

local M = {}

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

-- Build node title text from parsed semantic data
function M.build_from_parsed(node_info, parsed)
  local semantic_kind = (parsed and parsed.semantic_kind) or ""
  local node_type = (parsed and parsed.node_type)
    or (node_info and node_info.node_type)
    or ""
  local raw_text = (parsed and parsed.text) or (node_info and node_info.text) or ""

  local name = nil
  local metrics = {}
  local line_count = count_lines(node_info, raw_text)

  if semantic_kind == node_kinds_const.comment then
    local comment_name, char_count = extract.extract_comment_name(raw_text)
    name = comment_name
    if char_count and char_count > 0 then
      metrics = { tostring(char_count) .. " characters" }
    end

  elseif node_type == "for_statement" or node_type == "for_in_statement" then
    name = extract.extract_for_name(raw_text)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end

  elseif node_type == "if_statement" then
    name = extract.extract_if_name(raw_text)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end

  elseif node_type == "while_statement" or node_type == "repeat_statement" then
    local first_line = raw_text:match("^([^\n]+)") or raw_text
    name = extract.truncate(vim.trim(first_line), 50)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end

  elseif semantic_kind == node_kinds_const.assignment then
    name = extract.extract_assignment_name(raw_text)
    if raw_text:match("^%s*local%s") then
      metrics = { "local" }
    end

  else
    local first_line = raw_text:match("^([^\n]+)") or raw_text
    name = extract.truncate(vim.trim(first_line), 50)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end
  end

  return M.build({
    semantic_kind = semantic_kind,
    node_type = node_type,
    name = name,
    metrics = metrics,
  })
end

return M
