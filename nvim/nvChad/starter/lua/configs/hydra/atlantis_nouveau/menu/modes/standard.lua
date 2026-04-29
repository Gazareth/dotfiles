local interact = require("configs.hydra.atlantis_nouveau.menu.sections.interact")

local M = {}

function M.sections(result)
  return { interact.build(result) }
  -- navigate and create sections added here in v2
end

return M
