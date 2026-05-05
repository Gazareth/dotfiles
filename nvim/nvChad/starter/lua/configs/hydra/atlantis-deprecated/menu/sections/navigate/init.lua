local column_titles = require("configs.hydra.atlantis-deprecated.menu.column_titles")

-- Base navigate section when no actionable targets are found.
return {
  title = column_titles.navigate(),
  items = {
    { separator = true },
    { separator = true, label = " No navigate targets " },
    { separator = true },
  },
}
