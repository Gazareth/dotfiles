local actions  = require("configs.hydra.atlantis_nouveau.menu.sections.actions")
local navigate = require("configs.hydra.atlantis_nouveau.menu.sections.navigate")
local contents = require("configs.hydra.atlantis_nouveau.menu.sections.contents")

local M = {}

function M.sections(result)
  local sections = {}
  local function add(s) if s then sections[#sections + 1] = s end end
  add(navigate.build(result))
  add(contents.build(result))
  add(actions.build(result))
  return sections
end

return M
