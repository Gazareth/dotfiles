local interact = require("configs.hydra.atlantis_nouveau.menu.sections.interact")
local navigate = require("configs.hydra.atlantis_nouveau.menu.sections.navigate")

local M = {}

function M.sections(result)
  return {
    navigate.build(result),
    interact.build(result),
  }
end

return M
