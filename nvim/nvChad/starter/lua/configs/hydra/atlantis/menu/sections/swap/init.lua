local menu_schema = require("configs.hydra.atlantis.schema.menu")

local items = {}
for _, row in ipairs(menu_schema.swap.items) do
  items[#items + 1] = vim.tbl_extend("force", {
    action = "Treewalker " .. row.cmd,
  }, row)
end

return {
  title = menu_schema.swap.title,
  items = items,
}
