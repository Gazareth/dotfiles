local interact = require("configs.hydra.atlantis_nouveau.menu.sections.interact")
local navigate = require("configs.hydra.atlantis_nouveau.menu.sections.navigate")
local outline  = require("configs.hydra.atlantis_nouveau.menu.sections.outline")

local M = {}

function M.sections(result)
  local sections = {}
  local function add(s) if s then sections[#sections + 1] = s end end
  add(navigate.build(result))
  add(outline.build(result))
  add(interact.build(result))
  return sections
end

return M
