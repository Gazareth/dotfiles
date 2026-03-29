local NuiMenu = require("nui.menu")

local items_factory = require("configs.nui.lib.menu.section.items")

local M = {}
M.__index = M

-- Return all items that have a hotkey bound (id ~= nil).
function M:get_hotkeys()
	local hotkeys = {}
	for _, item in ipairs(self.items) do
		if item.id ~= nil then
			table.insert(hotkeys, item)
		end
	end
	return hotkeys
end

-- Build a Section from a raw section spec.
-- Owns item creation, width calculation, and NUI row assembly.
function M.create(section_spec)
	local section = setmetatable({}, M)
	section.title = section_spec.title

	local items, widths = items_factory.create(section_spec)
	section.items = items

	local nui_rows = { NuiMenu.item("") } -- Spacer line at the top

	for _, item in ipairs(items) do
		table.insert(nui_rows, item:as_nui_item(widths))
	end

	table.insert(nui_rows, NuiMenu.item("")) -- Spacer line at the bottom

	section.lines = nui_rows

	return section
end

return M
