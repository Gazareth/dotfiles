local M = {}

local ICON = {
  Function        = "󰊕",
  Call            = "󰡱",
  Assignment      = "󰆦",
  Conditional     = "󰘬",
  Loop            = "󰑖",
  Parameter       = "󰘨",
  ParameterList   = "󰘨",
  ReturnStatement = "󰌑",
  Body            = "󰅩",
  ExpressionList  = "󰅩",
  Comment         = "󰅺",
  FileRoot        = "󰈙",
}
local ICON_DEFAULT = "󰉿"

local function icon_for(classification)
  return ICON[classification] or ICON_DEFAULT
end

local KEYWORD_PREFIXES = {
  "local function ", "function ", "local ", "return ",
  "elseif ", "if ", "for ", "while ", "repeat ",
}

local function extract_name(label)
  if not label or label == "" then return nil end
  local s = label
  for _, kw in ipairs(KEYWORD_PREFIXES) do
    if s:sub(1, #kw) == kw then
      s = s:sub(#kw + 1)
      break
    end
  end
  local name = s:match("^([%w_%.]+)")
  return (name and name ~= "") and name or nil
end

local function range_str(range)
  return string.format("[%d:%d-%d:%d]",
    range.start_row + 1, range.start_col,
    range.end_row + 1,   range.end_col)
end

-- Normalise any of: full result, NavigationTarget, OutlineItem.
-- Returns: icon, name (may be nil), classification, range (may be nil), raw_type (may be nil).
local function extract(node_info)
  local icon, name, classification, range, raw_type

  if node_info.node and node_info.node.kind then
    -- Full survey result: inner.type gives the semantic kind ("function", "assignment", …)
    -- and overrides the raw AtlantisNode discriminant, matching the original menu_title logic.
    local inner = node_info.node.node
    if inner and inner.type then
      raw_type       = inner.type
      classification = inner.type:gsub("^%l", string.upper)
      name           = (inner.name and inner.name ~= "") and inner.name or nil
    else
      classification = node_info.node.kind:gsub("^%l", string.upper)
    end
    range = node_info.range
  elseif node_info.classification then
    -- NavigationTarget
    classification = node_info.classification
    range          = node_info.range
  elseif node_info.category then
    -- OutlineItem
    classification = node_info.category:gsub("^%l", string.upper)
    name           = extract_name(node_info.label)
    range          = node_info.range
  end

  icon = icon_for(classification or "")
  return icon, name, classification or "Node", range, raw_type
end

-- Compact form: "{icon} {name}"  (nav entries, namu items)
function M.short(node_info)
  local icon, name, classification, range = extract(node_info)
  local result = icon .. " " .. (name or classification)
  if vim.g.atlantis_debug and range then
    result = result .. " " .. range_str(range)
  end
  return result
end

-- Full form: "{icon} {name}  L{start}:{end} · {N} lines"  (menu title)
function M.long(node_info)
  local icon, name, classification, range, raw_type = extract(node_info)
  local result = icon .. " " .. (name or classification)
  if range then
    local start_line = range.start_row + 1
    local end_line   = range.end_row + 1
    local lines      = range.end_row - range.start_row + 1
    result = result .. " · L" .. start_line .. ":" .. end_line
           .. " · " .. lines .. (lines == 1 and " line" or " lines")
  end
  if vim.g.atlantis_debug then
    if raw_type then
      result = result .. " [" .. raw_type .. "]"
    elseif range then
      result = result .. " " .. range_str(range)
    end
  end
  return result
end

return M
