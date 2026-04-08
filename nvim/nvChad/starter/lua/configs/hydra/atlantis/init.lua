local menu_layout = require("configs.hydra.atlantis.menu.layout")

local M = {}

-- Atlantis menu layout bridge
function M.build_menu_spec()
  return menu_layout.build_menu_spec()
end

return M
