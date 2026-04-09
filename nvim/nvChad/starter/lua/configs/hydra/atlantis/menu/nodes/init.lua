local builder = require("configs.hydra.atlantis.menu.nodes.builder")

local M = {}

-- Node menu entrypoint
function M.get_node_menu_spec(runtime_ctx)
  return builder.get_node_menu_spec(runtime_ctx)
end

return M
