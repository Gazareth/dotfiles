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
    return string.rep("-", 20)
  end

  if type(item.heading) == "string" and item.heading ~= "" then
    return "== " .. item.heading .. " =="
  end

  if type(item._resolved_key) == "string" and item._resolved_key ~= "" then
    local icon = item.icon or ""
    local label = item.label or ""
    return string.format("%s %s [%s]", icon, label, item._resolved_key)
  end

  return item.label or ""
end

local function section_lines(section)
  local title = escape_hint_text(section.title or "")
  local lines = {}

  if title ~= "" then
    lines[#lines + 1] = title
    lines[#lines + 1] = string.rep("-", math.max(20, str_width(title)))
  else
    lines[#lines + 1] = ""
  end

  for _, item in ipairs(section.items or {}) do
    lines[#lines + 1] = escape_hint_text(render_item(item))
  end

  return lines
end

function M.build(sections)
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

  return {
    sections = normalized,
    hint = table.concat(output, "\n"),
  }
end

return M
