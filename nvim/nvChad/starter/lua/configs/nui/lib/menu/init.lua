local NuiMenu = require("nui.menu")
local NuiLayout = require("nui.layout")

local Section = require("configs.nui.lib.menu.section")
local layout = require("configs.nui.lib.menu.section.layout")

local M = {}
M.__index = M

M.sections = {} -- Section objects
M.prompt = nil

local function resolve_section_spec(menu, spec_or_fn)
	local spec = spec_or_fn

	if type(spec_or_fn) == "function" then
		local ok, result = pcall(spec_or_fn, menu)
		if not ok then
			vim.notify("Failed to resolve dynamic menu section: " .. tostring(result), vim.log.levels.ERROR)
			return nil, true
		end
		spec = result
	end

	if type(spec) == "table" and spec.__abort_open == true then
		local message = spec.__abort_message or "Menu could not be opened for the current context."
		vim.notify(message, vim.log.levels.WARN)
		return nil, true
	end

	if type(spec) ~= "table" then
		vim.notify("Invalid menu section spec. Expected table.", vim.log.levels.ERROR)
		return nil, false
	end

	return Section.create(spec), false
end

function M:resolve_sections()
	local resolved_sections = {}

	for _, section_spec in ipairs(self.section_specs or {}) do
		local section, should_abort = resolve_section_spec(self, section_spec)
		if should_abort then
			return nil
		end

		if section ~= nil then
			table.insert(resolved_sections, section)
		end
	end

	return resolved_sections
end

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
	local sections = self:resolve_sections()
	if sections == nil or #sections == 0 then
		return
	end

	self.sections = sections

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
	menu.section_specs = menu_spec or {}

	return menu
end

return M
