local fallback_navigate = require("configs.hydra.atlantis-deprecated.menu.sections.navigate")
local action_section = require("configs.hydra.atlantis-deprecated.menu.sections.action")
local create_section = require("configs.hydra.atlantis-deprecated.menu.sections.create")

local layout_sections = {}

function layout_sections.build_default(nav_column_spec)
  return { nav_column_spec or fallback_navigate, action_section, create_section }
end

function layout_sections.with_action_menu(action_menu_spec, nav_column_spec)
  return { nav_column_spec or fallback_navigate, action_menu_spec, create_section }
end

return layout_sections
