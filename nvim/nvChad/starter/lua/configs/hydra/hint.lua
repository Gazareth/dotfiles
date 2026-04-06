local M = {}

local HOTKEY_POOL = "1234567890abcdefghijklmnopqrstuvwxyz"

local function str_width(text)
  local s = text or ""
  -- Hydra's hydra_hint syntax conceals unescaped _, ^, \ characters (conceallevel=3).
  -- Escaped sequences like \_ are rendered as the bare char (backslash concealed).
  -- Strip these the same way Hydra does so column widths stay accurate.
  local visible = s:gsub("\\([_^\\])", "%1"):gsub("[_^\\]", "")
  return vim.fn.strdisplaywidth(visible)
end

local function pad_right(text, width)
  local value = text or ""
  local padding = width - str_width(value)
  if padding <= 0 then
    return value
  end
  return value .. string.rep(" ", padding)
end

-- Sanitize Hydra hint control characters
local function escape_hint_text(text)
  local value = text or ""
  -- Keep hint parser safe by removing marker chars from dynamic labels
  return value:gsub("_", "-"):gsub("%^", ""):gsub("\\", "/")
end

local function next_hotkey(used)
  for char in HOTKEY_POOL:gmatch(".") do
    if not used[char] then
      used[char] = true
      return char
    end
  end
  return nil
end

local function clone_item(item)
  return vim.tbl_extend("force", {}, item)
end

local function normalize_sections(sections)
  local normalized = {}
  local used = { q = true }

  for index = 1, 3 do
    local section = sections[index] or { title = "", items = {} }
    local rows = {}

    for _, raw_item in ipairs(section.items or {}) do
      local item = clone_item(raw_item)

      if type(item.key) == "string" and item.key ~= "" then
        local key = string.lower(item.key)
        if used[key] then
          key = next_hotkey(used)
        else
          used[key] = true
        end

        if key ~= nil then
          item._resolved_key = key
          rows[#rows + 1] = item
        end
      else
        rows[#rows + 1] = item
      end
    end

    normalized[index] = {
      title = section.title or "",
      items = rows,
    }
  end

  return normalized
end

local function render_item(item)
  if item.separator then
    if type(item.label) == "string" and item.label ~= "" then
      return "--- " .. item.label .. " ---"
    end
    return ""
  end

  if type(item.heading) == "string" and item.heading ~= "" then
    return "== " .. item.heading .. " =="
  end

  if type(item._resolved_key) == "string" and item._resolved_key ~= "" then
    local icon = item.icon or ""
    local label = item.label or ""
    return string.format("[%s] %s %s", item._resolved_key, icon, label)
  end

  return item.label or ""
end

local function section_lines(section)
  local title = escape_hint_text(section.title or "")
  local lines = {}

  if title ~= "" then
    lines[#lines + 1] = title
    lines[#lines + 1] = string.rep("-", math.max(20, str_width(title)))
    lines[#lines + 1] = ""
  else
    lines[#lines + 1] = ""
  end

  local first_item = true
  for _, item in ipairs(section.items or {}) do
    local rendered = escape_hint_text(render_item(item))
    -- Add padding before subheadings and labeled separators, but not for first item
    if not first_item and ((type(item.heading) == "string" and item.heading ~= "") or
       (item.separator and type(item.label) == "string" and item.label ~= "")) then
      lines[#lines + 1] = ""
    end
    if rendered ~= "" then
      lines[#lines + 1] = rendered
      first_item = false
    end
  end

  return lines
end

-- Title role-name formatter
local function format_title(title)
  if not title or title == "" then
    return title
  end

  -- Parse title candidate
  local function parse_candidate(candidate)
    local quoted_type, quoted_name = candidate:match('^(.-)%s+"([^"]+)"$')
    if quoted_type and quoted_name then
      return vim.trim(quoted_type), quoted_name
    end

    local colon_type, colon_name = candidate:match('^([^:]+):%s*(.+)$')
    if colon_type and colon_name then
      return vim.trim(colon_type), vim.trim(colon_name)
    end

    return nil, nil
  end

  local role, name = parse_candidate(title)
  if role and name then
    return "[" .. role .. "] " .. name
  end

  -- Icon-prefix fallback parse
  local first_token, rest = title:match("^(%S+)%s+(.+)$")
  if first_token and rest and first_token:match("[^%w_]") then
    role, name = parse_candidate(rest)
    if role and name then
      return "[" .. role .. "] " .. name
    end
  end

  return title
end

-- Main title lines
local function build_title_lines(title, total_width)
  local formatted_title = format_title(title or "")
  local safe_title = escape_hint_text(formatted_title)
  if safe_title == "" then
    return {}
  end

  local available_width = math.max(total_width, str_width(safe_title))
  local left = math.max(0, math.floor((available_width - str_width(safe_title)) / 2))
  local padded_title = string.rep(" ", left) .. safe_title

  return {
    padded_title,
    string.rep("=", available_width),
    "",
  }
end

-- Build hint text layout
function M.build(sections, opts)
  opts = opts or {}
  local normalized = normalize_sections(sections)
  local col_lines = {
    section_lines(normalized[1]),
    section_lines(normalized[2]),
    section_lines(normalized[3]),
  }

  local widths = { 0, 0, 0 }
  local max_rows = 0

  for column = 1, 3 do
    for _, line in ipairs(col_lines[column]) do
      widths[column] = math.max(widths[column], str_width(line))
    end
    max_rows = math.max(max_rows, #col_lines[column])
  end

  local output = {}
  for row = 1, max_rows do
    local c1 = pad_right(col_lines[1][row] or "", widths[1])
    local c2 = pad_right(col_lines[2][row] or "", widths[2])
    local c3 = pad_right(col_lines[3][row] or "", widths[3])
    output[#output + 1] = c1 .. " | " .. c2 .. " | " .. c3
  end

  -- Header above section columns
  local total_width = widths[1] + widths[2] + widths[3] + 6
  local title_lines = build_title_lines(opts.title, total_width)
  if #title_lines > 0 then
    local with_header = {}
    for _, line in ipairs(title_lines) do
      with_header[#with_header + 1] = line
    end
    for _, line in ipairs(output) do
      with_header[#with_header + 1] = line
    end
    output = with_header
  end

  return {
    sections = normalized,
    hint = table.concat(output, "\n"),
  }
end

return M
