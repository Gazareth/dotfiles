local fallback_jump = require("configs.hydra.atlantis.menu.sections.jump")
local action_section = require("configs.hydra.atlantis.menu.sections.action")
local swap_section = require("configs.hydra.atlantis.menu.sections.swap")

local layout_sections = {}

-- Return base section list used when no node-specific spec is available
function layout_sections.build_default(jump_spec)
  return { jump_spec or fallback_jump, action_section, swap_section }
end

-- Return section list with a provided action menu section override
function layout_sections.with_action_menu(action_menu_spec, jump_spec)
  return { jump_spec or fallback_jump, action_menu_spec, swap_section }
end

return layout_sections
