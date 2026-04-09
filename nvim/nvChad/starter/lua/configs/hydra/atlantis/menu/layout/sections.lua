-- Build consistent section ordering for layout assembly
local jump_section = require("configs.hydra.atlantis.menu.sections.jump")
local modify_section = require("configs.hydra.atlantis.menu.sections.modify")
local swap_section = require("configs.hydra.atlantis.menu.sections.swap")

local M = {}

-- Return base section list used when no node-specific spec is available
function M.build_default()
  return { jump_section, modify_section, swap_section }
end

-- Return section list with a provided modify section override
function M.with_modify(modify_spec)
  return { jump_section, modify_spec, swap_section }
end

return M
