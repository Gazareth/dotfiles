local menu_item = require("configs.nui.lib.menu.item")
local items = require("configs.nui.lib.menu.items")

-- Create, mount, and wire a popup menu from a menu spec.
local function open_menu(menu_spec)
  local Menu = require("nui.menu")
  local event = require("nui.utils.autocmd").event

  local rendered = items.build(menu_spec, Menu)
  local prompt = menu_spec.prompt or "Actions"

  local popup = Menu({
    relative = "editor",
    position = "50%",
    size = {
      width = rendered.popup_width,
      height = rendered.popup_height,
    },
    border = {
      style = "rounded",
      text = {
        top = " " .. prompt .. " ",
        top_align = "center",
      },
    },
    win_options = {
      cursorline = false,
    },
  }, {
    lines = rendered.lines,
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

  for key, item in pairs(rendered.key_to_item) do
    vim.keymap.set("n", key, function()
      popup:unmount()
      menu_item.run(menu_spec, item)
    end, {
      buffer = popup.bufnr,
      nowait = true,
      silent = true,
    })
  end
end

-- Link a menu object to a top-level keymap.
local function bind_menu_to_keymaps(menu, mode, lhs, desc)
  vim.keymap.set(mode, lhs, function()
    open_menu(menu)
  end, { desc = desc })
end

-- Build a full menu object from a lean menu spec.
local function create_menu_from_spec(menu_spec)
  local menu = vim.tbl_extend("force", {}, menu_spec)

  menu.open = function()
    open_menu(menu)
  end

  menu.bind = function(mode, lhs, desc)
    bind_menu_to_keymaps(menu, mode, lhs, desc)
  end

  return menu
end

return create_menu_from_spec
