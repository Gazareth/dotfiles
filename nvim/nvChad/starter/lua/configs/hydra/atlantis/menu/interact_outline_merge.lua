local column_titles = require("configs.hydra.atlantis.menu.column_titles")

local M = {}

-- Build the interact section by merging outline items with existing interact items when outline is open, otherwise return interact as is
function M.build_interact_section(interact_raw, outline_items)
  if type(interact_raw) ~= "table" or interact_raw.__abort_open == true then
    return interact_raw
  end

  local title = column_titles.interact()
  local items

  if type(outline_items) ~= "table" or #outline_items == 0 then
    items = interact_raw.items
  else
    items = outline_items
  end

  return {
    title = title,
    items = items,
  }
end

return M
