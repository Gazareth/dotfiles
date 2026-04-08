local nodes = require("configs.hydra.atlantis.menu.nodes")

local M = {}

-- Node menu entrypoint
function M.get_node_menu_spec()
  return nodes.get_node_menu_spec()
end

return M
