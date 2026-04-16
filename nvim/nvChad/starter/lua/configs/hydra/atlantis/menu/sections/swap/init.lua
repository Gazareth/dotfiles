local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local menu_schema = require("configs.hydra.atlantis.schema.menu")

local items = {}
for _, row in ipairs(menu_schema.swap.items) do
  items[#items + 1] = vim.tbl_extend("force", {
    action = "Atlantis " .. row.cmd,
  }, row)
end

return {
  title = column_titles.swap(),
  items = items,
}
