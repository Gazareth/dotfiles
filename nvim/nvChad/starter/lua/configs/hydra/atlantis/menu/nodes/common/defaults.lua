local generic = require("configs.hydra.atlantis.menu.nodes.generic")

local M = {}

-- Node fallback builder
function M.build(node_info, parsed)
  return generic.build(node_info, parsed)
end

return M
