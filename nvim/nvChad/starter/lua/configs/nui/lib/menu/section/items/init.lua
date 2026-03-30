local Item = require("configs.nui.lib.menu.section.items.item")

local M = {}

local function recalculate_widths(widths, item_widths)
  return {
    icon = math.max(widths.icon, item_widths.icon),
    text = math.max(widths.text, item_widths.text),
    key = math.max(widths.key, item_widths.key),
  }
end

-- Build Item objects and calculate max column widths from item specs
-- Returns: items (list), widths (table with icon/text/key maxima)
function M.create(item_specs)
  local items = {}
  local widths = { icon = 0, text = 0, key = 0 }

  for _, item_spec in ipairs(item_specs or {}) do
    local item = Item.create(nil, item_spec)
    table.insert(items, item)

    widths = recalculate_widths(widths, item:get_widths())
  end

  return items, widths
end

return M
