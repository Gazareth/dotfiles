local NuiMenu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local Item = require("configs.nui.lib.menu.item")
local create_menu_items = require("configs.nui.lib.menu.items")
local layout = require("configs.nui.lib.menu.layout")
local M = {}
M.__index = M

M.lines = {} -- Nui renderable content
M.guts = {} -- Menu choices with callback
M.prompt = nil

-- Build and open the NUI popup for this menu.
function M:open()
    local prompt = self.prompt or "Actions"

    local popup = NuiMenu(layout.create_menu_layout(self.lines, prompt), {
        lines = self.lines,
        keymap = {
            close = {"q", "<Esc>"},
            submit = {},
            focus_next = {},
            focus_prev = {}
        }
    })

    -- Pop up the popup
    popup:mount()

    -- Mount all items to enable their hotkeys (they are set against the buffer, so not permanent)
    for _, item in ipairs(self.guts) do
        item:mount(popup.bufnr, function()
            popup:unmount()
        end)
    end

    -- Setup automatic exit when leaving the buffer
    popup:on(event.BufLeave, function()
        popup:unmount()
    end)
end

-- Bind this menu to a keymap.
function M:bind(mode, lhs, desc)
    vim.keymap.set(mode, lhs, function()
        self:open()
    end, {
        desc = desc
    })
end

-- Create a new Menu object from a spec table.
function M.create(title, menu_spec)
    local menu = setmetatable({}, M)
    menu.prompt = title

    menu.lines, menu.guts = create_menu_items(menu_spec)
    return menu
end

return M
