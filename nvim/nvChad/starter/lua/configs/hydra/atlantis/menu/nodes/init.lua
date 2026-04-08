local builder = require("configs.hydra.atlantis.menu.nodes.builder")

local M = {}

-- Node menu entrypoint
function M.get_node_menu_spec()
  return builder.get_node_menu_spec()
end

return M
