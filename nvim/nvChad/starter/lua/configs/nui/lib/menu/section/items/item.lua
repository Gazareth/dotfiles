local NuiMenu = require("nui.menu")

local str = require("configs.nui.lib.string")
local callback = require("configs.nui.lib.menu.section.items.callback")
local layout = require("configs.nui.lib.menu.section.layout")

local M = {}
M.__index = M

local function create_separator(text, char)
  return NuiMenu.separator(text or "", {
    char = char or "─",
    text_align = "left",
  })
end

-- Calculate display widths used for row alignment.
function M:get_widths()
  if self.separator or type(self.heading) == "string" then
    return { icon = 0, text = 0, key = 0 }
  end

  return {
    icon = vim.fn.strdisplaywidth(str.non_empty_or(self.icon, "")),
    text = vim.fn.strdisplaywidth(self.label or ""),
    key = vim.fn.strdisplaywidth(self.id or ""),
  }
end

-- Prepare a line for rendering by nui (with aligned icon, label, and shortcut key).
function M:format(widths)
  local icon = str.non_empty_or(self.icon, "")
  local text = self.label or ""
  local key = self.id or ""

  local parts = {
    "   ",
    layout.pad_center(icon, widths.icon),
    "  ",
    layout.pad_right(text, widths.text),
  }

  if widths.key > 0 then
    parts[#parts + 1] = "  "
    parts[#parts + 1] = layout.pad_left(key, widths.key)
  end

  parts[#parts + 1] = "  "

  return table.concat(parts)
end

function M:as_nui_item(widths)
  if type(self.heading) == "string" and self.heading ~= "" then
    return create_separator(self.heading, " ")
  end

  if self.separator then
    return create_separator(self.label)
  end

  return NuiMenu.item(self:format(widths))
end

-- Register a buffer-local keymap that closes the menu and runs this item's action.
function M:mount(buffer, close_menu)
  if self.id == nil then
    return
  end

  vim.keymap.set("n", self.id, function()
    close_menu()
    callback.execute(self)
  end, {
    buffer = buffer,
    nowait = true,
    silent = true,
  })
end

-- Build an Item from a raw spec.
function M.create(menu, item_spec)
  local item = vim.tbl_extend("force", {}, item_spec)
  item.id = str.to_lower(item.key, nil)
  item._menu = menu
  return setmetatable(item, M)
end

return M
