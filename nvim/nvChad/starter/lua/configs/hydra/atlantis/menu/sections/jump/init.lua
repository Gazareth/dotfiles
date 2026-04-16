local column_titles = require("configs.hydra.atlantis.menu.column_titles")

-- Fallback jump section used when prebuilt jump spec is unavailable
return {
  title = column_titles.jump(),
  items = {
    { separator = true },
    { separator = true, label = " No jump targets " },
    { separator = true },
  },
}
