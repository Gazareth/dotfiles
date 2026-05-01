local interact = require("configs.hydra.atlantis_nouveau.menu.sections.interact")
local navigate = require("configs.hydra.atlantis_nouveau.menu.sections.navigate")

local M = {}

function M.sections(result, all_results)
  return {
    navigate.build(result, all_results),
    interact.build(result),
  }
end

return M
