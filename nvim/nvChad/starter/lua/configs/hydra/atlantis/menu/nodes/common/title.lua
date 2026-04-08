local node_kinds_const = require("configs.hydra.atlantis.registry.node_tiers").node_kinds

local M = {}

-- Icons per semantic kind (shown inside the bracket label)
local kind_icons = {
  [node_kinds_const.declaration]   = "ƒ",
  [node_kinds_const.comment]       = "🗨",
  [node_kinds_const.assignment]    = "◈",
  [node_kinds_const.control_frame] = "⊡",
  [node_kinds_const.call]          = "⊛",
  [node_kinds_const.identifier]    = "·",
  [node_kinds_const.string]        = "❝",
  [node_kinds_const.collection]    = "⊏",
  [node_kinds_const.property]      = "⊕",
  [node_kinds_const.statement]     = "·",
}

-- Labels per semantic kind
local kind_labels = {
  [node_kinds_const.declaration]   = "Function",
  [node_kinds_const.comment]       = "Comment",
  [node_kinds_const.assignment]    = "Assignment",
  [node_kinds_const.control_frame] = "Block",
  [node_kinds_const.call]          = "Call",
  [node_kinds_const.identifier]    = "Identifier",
  [node_kinds_const.string]        = "String",
  [node_kinds_const.collection]    = "Collection",
  [node_kinds_const.property]      = "Property",
  [node_kinds_const.statement]     = "Statement",
}

-- More specific labels per raw node type (overrides kind-level)
local type_labels = {
  for_statement        = "For loop",
  for_in_statement     = "For loop",
  if_statement         = "If",
  while_statement      = "While loop",
  repeat_statement     = "Repeat",
  function_call        = "Call",
  method_definition    = "Method",
}

-- More specific icons per raw node type (overrides kind-level)
local type_icons = {
  for_statement        = "➰",
  for_in_statement     = "➰",
  if_statement         = "⁇",
  while_statement      = "↺",
  repeat_statement     = "↺",
  method_definition    = "·",
}

-- Label for a node: raw type wins over semantic kind for specificity
function M.resolve_label(semantic_kind, node_type)
  return type_labels[node_type] or kind_labels[semantic_kind] or "Node"
end

-- Icon for a node: raw type wins over semantic kind for specificity
function M.resolve_icon(semantic_kind, node_type)
  return type_icons[node_type] or kind_icons[semantic_kind] or ""
end

-- Format a list of metrics as "{ m1, m2, ... }" or ""
local function format_metrics(list)
  if type(list) ~= "table" or #list == 0 then
    return ""
  end

  local parts = {}
  for _, m in ipairs(list) do
    if type(m) == "string" and m ~= "" then
      parts[#parts + 1] = m
    end
  end

  if #parts == 0 then
    return ""
  end

  return "{ " .. table.concat(parts, ", ") .. " }"
end

-- "[Label icon] name { m1, m2 }" from explicit opts
-- opts: { label, icon, name, metrics, semantic_kind, node_type }
function M.build(opts)
  local label = opts.label or M.resolve_label(opts.semantic_kind, opts.node_type)
  local icon = opts.icon or M.resolve_icon(opts.semantic_kind, opts.node_type)

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

-- Truncate text to max_len, appending "..." if cut
function M.truncate(text, max_len)
  max_len = max_len or 40
  if not text or text == "" then
    return ""
  end
  if #text <= max_len then
    return text
  end
  return text:sub(1, max_len) .. "..."
end

-- Comment preview and full length
function M.extract_comment_name(raw_text)
  if not raw_text then
    return nil, nil
  end

  -- Block comment: --[[ ... ]]
  local block = raw_text:match("^%-%-%[%[(.-)%]%]$")
  if block then
    local content = vim.trim(block:match("^[^\n]+") or block)
    return M.truncate(content, 24), #content
  end

  -- Line comment: -- content
  local line = raw_text:match("^%-%-+%s*(.+)")
  if line then
    local content = vim.trim(line)
    return M.truncate(content, 24), #content
  end

  local fallback = vim.trim(raw_text)
  return M.truncate(fallback, 24), #fallback
end

-- Extract iterator/condition from for-loop text
function M.extract_for_name(raw_text)
  if not raw_text then
    return nil
  end

  -- for ... in expr do (generic-case pattern)
  local iterator = raw_text:match("[Ff][Oo][Rr]%s+.-%s+[Ii][Nn]%s+(.-)%s+[Dd][Oo]")
  if iterator then
    return M.truncate(vim.trim(iterator), 40)
  end

  -- Numeric: for i = expr do
  local numeric = raw_text:match("[Ff][Oo][Rr]%s+(.-)%s+[Dd][Oo]")
  if numeric then
    return M.truncate(vim.trim(numeric), 40)
  end

  return nil
end

-- Extract condition from if-statement text
function M.extract_if_name(raw_text)
  if not raw_text then
    return nil
  end

  local condition = raw_text:match("[Ii][Ff]%s+(.-)%s+[Tt][Hh][Ee][Nn]")
  if condition then
    return M.truncate(vim.trim(condition), 40)
  end

  return nil
end

-- Extract variable name from assignment text
function M.extract_assignment_name(raw_text)
  if not raw_text then
    return nil
  end

  -- local x = ...
  local local_name = raw_text:match("^%s*[Ll][Oo][Cc][Aa][Ll]%s+([%w_]+)")
  if local_name then
    return local_name
  end

  -- x = ... or x.y = ...
  local plain_name = raw_text:match("^%s*([%w_][%w_.:]*[%w_]?)%s*=")
  if plain_name then
    return plain_name
  end

  return nil
end

-- Count lines in a node using row positions (or fall back to text)
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

-- Generic title using heuristic extraction (used by the fallback builder)
-- node_info and parsed are both optional but at least one should be present
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
    local comment_name, char_count = M.extract_comment_name(raw_text)
    name = comment_name
    if char_count and char_count > 0 then
      metrics = { tostring(char_count) .. " characters" }
    end

  elseif node_type == "for_statement" or node_type == "for_in_statement" then
    name = M.extract_for_name(raw_text)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end

  elseif node_type == "if_statement" then
    name = M.extract_if_name(raw_text)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end

  elseif node_type == "while_statement" or node_type == "repeat_statement" then
    -- First meaningful line for while/repeat
    local first_line = raw_text:match("^([^\n]+)") or raw_text
    name = M.truncate(vim.trim(first_line), 50)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end

  elseif semantic_kind == node_kinds_const.assignment then
    name = M.extract_assignment_name(raw_text)
    -- Flag local assignments
    if raw_text:match("^%s*local%s") then
      metrics = { "local" }
    end

  else
    -- Generic: first line truncated
    local first_line = raw_text:match("^([^\n]+)") or raw_text
    name = M.truncate(vim.trim(first_line), 50)
    if line_count > 1 then
      metrics = { line_count .. " lines" }
    end
  end

  return M.build({
    semantic_kind = semantic_kind,
    node_type     = node_type,
    name          = name,
    metrics       = metrics,
  })
end

return M
