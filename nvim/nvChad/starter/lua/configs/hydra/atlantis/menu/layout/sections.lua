local fallback_navigate = require("configs.hydra.atlantis.menu.sections.navigate")
local action_section = require("configs.hydra.atlantis.menu.sections.action")
local create_section = require("configs.hydra.atlantis.menu.sections.create")

local layout_sections = {}

function layout_sections.build_default(navigate_spec)
  return { navigate_spec or fallback_navigate, action_section, create_section }
end

function layout_sections.with_action_menu(action_menu_spec, navigate_spec)
  return { navigate_spec or fallback_navigate, action_menu_spec, create_section }
end

return layout_sections
