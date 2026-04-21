local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local menu_schema = require("configs.hydra.atlantis.schema.menu")

local create_cfg = menu_schema.create

local rows = {}
for _, row in ipairs(create_cfg.items or {}) do
  rows[#rows + 1] = {
    key = row.key,
    icon = row.icon,
    label = row.label,
    action = function() end,
  }
end

return {
  title = column_titles.create(),
  items = rows,
}
