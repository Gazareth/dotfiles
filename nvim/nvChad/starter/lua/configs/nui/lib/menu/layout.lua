local str = require("configs.nui.lib.string")
local unpack_values = table.unpack or unpack

local M = {}

local function max_or_zero(values)
  if #values == 0 then
    return 0
  end

  return math.max(unpack_values(values))
end

-- Pad text on the left to a target display width.
function M.pad_left(value, width)
  local text = value or ""
  local missing = width - str.display_width(text)
  if missing > 0 then
    return string.rep(" ", missing) .. text
  end

  return text
end

-- Pad text on the right to a target display width.
function M.pad_right(value, width)
  local text = value or ""
  local missing = width - str.display_width(text)
  if missing > 0 then
    return text .. string.rep(" ", missing)
  end

  return text
end

-- Center text inside a fixed display width.
function M.pad_center(value, width)
  local text = value or ""
  local missing = width - str.display_width(text)
  if missing > 0 then
    local left = math.floor(missing / 2)
    local right = missing - left
    return string.rep(" ", left) .. text .. string.rep(" ", right)
  end

  return text
end

-- Build popup layout options from rendered lines and prompt.
function M.create_menu_layout(lines, prompt)
  local line_widths = vim.tbl_map(function(line)
    return str.display_width(line.text)
  end, lines or {})

  local max_label_len = max_or_zero(line_widths)
  local title_width = str.display_width(" " .. (prompt or "Actions"))

  return {
    relative = "editor",
    position = "50%",
    size = {
      width = math.max(max_label_len + 2, title_width + 2),
      height = math.max(#(lines or {}), 1),
    },
    border = {
      style = "rounded",
      text = {
        top = " " .. (prompt or "Actions") .. " ",
        top_align = "center",
      },
    },
    win_options = {
      cursorline = false,
    },
  }
end

return M
