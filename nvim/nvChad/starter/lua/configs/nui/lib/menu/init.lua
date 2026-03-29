local NuiMenu = require("nui.menu")
local NuiLayout = require("nui.layout")

local Section = require("configs.nui.lib.menu.section")
local layout = require("configs.nui.lib.menu.section.layout")

local M = {}
M.__index = M

M.sections = {} -- Section objects
M.prompt = nil

local function create_nui_section(section, section_layout)
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
	local menu_layout = layout.create_menu_layout(self.sections, prompt)
	local nui_sections = {}
	local boxes = {}

	for index, section in ipairs(self.sections) do
		local nui_section = create_nui_section(section, menu_layout.sections[index])
		nui_sections[index] = nui_section
		boxes[index] = NuiLayout.Box(nui_section, { size = menu_layout.sections[index].size })
	end

	local popup = NuiLayout(menu_layout.layout, NuiLayout.Box(boxes, { dir = "row" }))

	local function close_menu()
		popup:unmount()
	end

	popup:mount()

	-- Collect hotkeys from all sections
	local all_hotkeys = {}
	for _, section in ipairs(self.sections) do
		vim.list_extend(all_hotkeys, section:get_hotkeys())
	end

	for _, nui_section in ipairs(nui_sections) do
		vim.keymap.set("n", "q", close_menu, { buffer = nui_section.bufnr, nowait = true, silent = true })
		vim.keymap.set("n", "<Esc>", close_menu, { buffer = nui_section.bufnr, nowait = true, silent = true })

		for _, item in ipairs(all_hotkeys) do
			item:mount(nui_section.bufnr, close_menu)
		end
	end

	vim.api.nvim_set_current_win(nui_sections[1].winid)
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

	menu.sections = {}
	for _, section_spec in ipairs(menu_spec) do
		table.insert(menu.sections, Section.create(section_spec))
	end

	return menu
end

return M
