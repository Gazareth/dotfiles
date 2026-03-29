local Item = require("configs.nui.lib.menu.item")
local create_menu_items = require("configs.nui.lib.menu.items")
local layout = require("configs.nui.lib.menu.layout")

local Menu = {}
Menu.__index = Menu

-- Build and open the NUI popup for this menu.
function Menu:open()
  local NuiMenu = require("nui.menu")
  local event = require("nui.utils.autocmd").event

  local items = vim.tbl_map(function(item_spec)
    return Item.create(self, item_spec)
  end, self.items or {})

  local lines = create_menu_items(items, NuiMenu)
  local prompt = self.prompt or "Actions"

  local popup = NuiMenu(layout.create_menu_layout(lines, prompt), {
    lines = lines,
    keymap = {
      close = { "q", "<Esc>" },
      submit = {},
      focus_next = {},
      focus_prev = {},
    },
  })

  popup:mount()

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)

  for _, item in ipairs(items) do
    item:mount(popup.bufnr, function()
      popup:unmount()
    end)
  end
end

-- Bind this menu to a keymap.
function Menu:bind(mode, lhs, desc)
  vim.keymap.set(mode, lhs, function()
    self:open()
  end, { desc = desc })
end

-- Create a new Menu object from a spec table.
function Menu.create(menu_spec)
  return setmetatable(vim.tbl_extend("force", {}, menu_spec), Menu)
end

-- Entry point: create a Menu from a spec.
local function setup_menu(menu_spec)
  return Menu.create(menu_spec)
end

return setup_menu
