local NuiMenu = require("nui.menu")
local NuiLayout = require("nui.layout")

local create_menu_items = require("configs.nui.lib.menu.items")
local layout = require("configs.nui.lib.menu.layout")
local M = {}
M.__index = M

M.lists = {} -- Renderable menu sections
M.guts = {} -- Menu choices with callback
M.prompt = nil

local function create_menu_section(section, section_layout)
	return NuiMenu(
		vim.tbl_deep_extend("force", {
			enter = false,
			focusable = false,
			size = section_layout.size,
		}, section_layout.popup),
		{
			lines = section.lines,
			keymap = {
				close = {},
				submit = {},
				focus_next = {},
				focus_prev = {},
			},
		}
	)
end

-- Build and open the NUI popup for this menu.
function M:open()
	local prompt = self.prompt or "Actions"
	local menu_layout = layout.create_menu_layout(self.lists, prompt)
	local sections = {}
	local boxes = {}

	for index, list in ipairs(self.lists) do
		local section = create_menu_section(list, menu_layout.sections[index])
		sections[index] = section
		boxes[index] = NuiLayout.Box(section, { size = menu_layout.sections[index].size })
	end

	local popup = NuiLayout(menu_layout.layout, NuiLayout.Box(boxes, { dir = "row" }))

	local function close_menu()
		popup:unmount()
	end

	popup:mount()

	for _, section in ipairs(sections) do
		vim.keymap.set("n", "q", close_menu, { buffer = section.bufnr, nowait = true, silent = true })
		vim.keymap.set("n", "<Esc>", close_menu, { buffer = section.bufnr, nowait = true, silent = true })

		for _, item in ipairs(self.guts) do
			item:mount(section.bufnr, close_menu)
		end
	end

	vim.api.nvim_set_current_win(sections[1].winid)
end

-- Bind this menu to a keymap.
function M:bind(mode, lhs, desc)
	vim.keymap.set(mode, lhs, function()
		self:open()
	end, {
		desc = desc,
	})
end

-- Create a new Menu object from a spec table.
function M.create(title, menu_spec)
	local menu = setmetatable({}, M)
	menu.prompt = title

	menu.lists, menu.guts = create_menu_items(menu_spec)
	return menu
end

return M
