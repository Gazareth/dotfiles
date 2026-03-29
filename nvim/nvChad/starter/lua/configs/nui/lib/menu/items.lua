local item = require("configs.nui.lib.menu.item")
local str = require("configs.nui.lib.string")

local M = {}

-- Measure rendered width (used to assist with spacing)
local function display_width(value)
  return vim.fn.strdisplaywidth(value or "")
end

-- Pad text on the left to a target display width.
local function pad_left(value, width)
  local text = value or ""
  local missing = width - display_width(text)
  if missing > 0 then
    return string.rep(" ", missing) .. text
  end

  return text
end

-- Pad text on the right to a target display width.
local function pad_right(value, width)
  local text = value or ""
  local missing = width - display_width(text)
  if missing > 0 then
    return text .. string.rep(" ", missing)
  end

  return text
end

-- Center text inside a fixed display width.
local function pad_center(value, width)
  local text = value or ""
  local missing = width - display_width(text)
  if missing > 0 then
    local left = math.floor(missing / 2)
    local right = missing - left
    return string.rep(" ", left) .. text .. string.rep(" ", right)
  end

  return text
end

-- Build one rendered menu row with aligned icon, label, and shortcut key.
local function format_item(menu_item, widths)
  local icon = str.non_empty_or(menu_item.icon, "")
  local text = menu_item.label or ""
  local key = item.normalize_key(menu_item.key) or ""

  local parts = {
    "   ",
    pad_center(icon, widths.icon),
    "  ",
    pad_right(text, widths.text),
  }

  if widths.key > 0 then
    parts[#parts + 1] = "  "
    parts[#parts + 1] = pad_left(key, widths.key)
  end

  parts[#parts + 1] = "  "

  return table.concat(parts)
end

-- Convert menu specs into rendered lines, key lookup, and popup sizing.
function M.build(menu, Menu)
  local key_to_item = {}
  local widths = { icon = 0, text = 0, key = 0 }

  for _, menu_item in ipairs(menu.items or {}) do
    local item_key = item.normalize_key(menu_item.key)
    if item_key then
      key_to_item[item_key] = menu_item
      widths.key = math.max(widths.key, display_width(item_key))
    end

    widths.icon = math.max(widths.icon, display_width(str.non_empty_or(menu_item.icon, "")))
    widths.text = math.max(widths.text, display_width(menu_item.label or ""))
  end

  local lines = { Menu.item("") }
  for _, menu_item in ipairs(menu.items or {}) do
    lines[#lines + 1] = Menu.item(format_item(menu_item, widths))
  end
  lines[#lines + 1] = Menu.item("")

  local max_label_len = 0
  for _, line in ipairs(lines) do
    max_label_len = math.max(max_label_len, vim.fn.strdisplaywidth(line.text or ""))
  end

  local prompt = menu.prompt or "Actions"
  local title_width = display_width(" " .. prompt)

  return {
    lines = lines,
    key_to_item = key_to_item,
    popup_width = math.max(max_label_len + 2, title_width + 2),
    popup_height = math.max(#lines, 1),
  }
end

return M
