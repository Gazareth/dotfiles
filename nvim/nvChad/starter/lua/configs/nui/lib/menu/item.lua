local str = require("configs.nui.lib.string")
local layout = require("configs.nui.lib.menu.layout")

local M = {}
M.__index = M

local function get_module_path(item)
  if type(item.module) ~= "string" then
    return nil
  end

  if type(item.submodule) == "string" and item.submodule ~= "" then
    return item.module .. "." .. item.submodule
  end

  return item.module
end

local function run_module_function(item)
  local module_path = get_module_path(item)
  if module_path == nil or type(item.fn) ~= "string" then
    return false
  end

  local ok, mod = pcall(require, module_path)
  if not ok then
    vim.notify("Failed to load module: " .. module_path, vim.log.levels.ERROR)
    return true
  end

  local fn = mod[item.fn]
  if type(fn) ~= "function" then
    vim.notify("Menu item is missing function: " .. item.fn, vim.log.levels.ERROR)
    return true
  end

  fn(item)
  return true
end

local function execute_item(item)
  if type(item.action) == "function" then
    item.action(item)
    return
  end

  if type(item.action) == "string" and item.action ~= "" then
    local ok, err = pcall(vim.cmd, item.action)
    if not ok then
      vim.notify("Failed to run command: " .. item.action .. " (" .. tostring(err) .. ")", vim.log.levels.ERROR)
    end
    return
  end

  if run_module_function(item) then
    return
  end

  if type(item._menu.resolve) == "function" then
    item._menu.resolve(item)
  end
end

-- Calculate display widths used for row alignment.
function M:get_widths()
  return {
    icon = vim.fn.strdisplaywidth(str.non_empty_or(self.icon, "")),
    text = vim.fn.strdisplaywidth(self.label or ""),
    key = vim.fn.strdisplaywidth(self.id or ""),
  }
end

-- Build one rendered menu line (with aligned icon, label, and shortcut key).
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

-- Register a buffer-local keymap that closes the menu and runs this item's action.
function M:mount(buffer, close_menu)
  if self.id == nil then
    return
  end

  vim.keymap.set("n", self.id, function()
    close_menu()
    execute_item(self)
  end, {
    buffer = buffer,
    nowait = true,
    silent = true,
  })
end

-- Build a MenuItem from a raw spec, bound to its parent menu.
function M.create(menu, item_spec)
  local item = vim.tbl_extend("force", {}, item_spec)
  item.id = str.to_lower(item.key, nil)
  item._menu = menu
  return setmetatable(item, M)
end

return M
