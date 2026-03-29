-- Recalculate max widths with a single menu item's measured widths.
local function recalculate_widths(widths, item_widths)
  return {
    icon = math.max(widths.icon, item_widths.icon),
    text = math.max(widths.text, item_widths.text),
    key = math.max(widths.key, item_widths.key),
  }
end

-- Build rendered menu lines from menu items.
local function create_menu_items(menu_items, Menu)
  local widths = { icon = 0, text = 0, key = 0 }

  -- Find the largest width icon, label, and id among all items (for padding)
  for _, menu_item in ipairs(menu_items or {}) do
    widths = recalculate_widths(widths, menu_item:get_widths())
  end

  -- Create actual nui.nvim Menu.item objects
  local lines = { Menu.item("") }
  for _, menu_item in ipairs(menu_items or {}) do
    table.insert(lines, Menu.item(menu_item:format(widths)))
  end
  table.insert(lines, Menu.item(""))

  return lines
end

return create_menu_items
