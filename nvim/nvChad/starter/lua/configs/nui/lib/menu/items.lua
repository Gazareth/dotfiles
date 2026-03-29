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

-- Build rendered menu lines from menu items.
local function create_menu_items(menu_spec)
  local items = {}
  local widths = { icon = 0, text = 0, key = 0 }

  for _, item_spec in ipairs(menu_spec or {}) do
    -- Create our own Item
    local item = Item.create(nil, item_spec)
    table.insert(items, item)

    -- Find the largest width icon, label, and id among all items (for padding)
    widths = recalculate_widths(widths, item:get_widths())
  end

  -- Create actual nui.nvim Menu.item objects
  local nui_rows = { NuiMenu.item("") } -- Spacer line at the top

  for _, menu_item in ipairs(items) do
    table.insert(nui_rows, menu_item:as_nui_item(widths))
  end

  table.insert(nui_rows, NuiMenu.item("")) -- Spacer line at the bottom

  return nui_rows, items
end

return create_menu_items
