local NuiMenu = require("nui.menu")
local Item = require("configs.nui.lib.menu.item")

-- Recalculate max widths with a single menu item's measured widths.
local function recalculate_widths(widths, item_widths)
	return {
		icon = math.max(widths.icon, item_widths.icon),
		text = math.max(widths.text, item_widths.text),
		key = math.max(widths.key, item_widths.key),
	}
end

local function create_list(section_spec)
	local items = {}
	local widths = { icon = 0, text = 0, key = 0 }

	for _, item_spec in ipairs(section_spec) do
		local item = Item.create(nil, item_spec)
		table.insert(items, item)

		widths = recalculate_widths(widths, item:get_widths())
	end

	local nui_rows = { NuiMenu.item("") } -- Spacer line at the top

	for _, menu_item in ipairs(items) do
		table.insert(nui_rows, menu_item:as_nui_item(widths))
	end

	table.insert(nui_rows, NuiMenu.item("")) -- Spacer line at the bottom

	return {
		title = section_spec.title,
		lines = nui_rows,
		items = items,
	}end

-- Build rendered menu lists from menu items.
local function create_menu_items(menu_spec)
	local lists = {}
	local items = {}

	for _, section_spec in ipairs(menu_spec) do
		local list = create_list(section_spec)
		table.insert(lists, list)
		vim.list_extend(items, list.items)
	end

	return lists, items
end

return create_menu_items
