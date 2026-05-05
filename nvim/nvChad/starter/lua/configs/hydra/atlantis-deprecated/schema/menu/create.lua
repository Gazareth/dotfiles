local column_titles = require("configs.hydra.atlantis-deprecated.menu.column_titles")

local M = {}

M.title = column_titles.create()

M.items = {
  { key = "1", icon = "+", label = "Append statement to body (placeholder)" },
  { key = "2", icon = "^", label = "Prepend statement to body (placeholder)" },
  { key = "3", icon = "󰈔", label = "Add import (placeholder)" },
  { key = "4", icon = "󰌘", label = "New function above (placeholder)" },
  { key = "5", icon = "󰌙", label = "New function below (placeholder)" },
}

return M
