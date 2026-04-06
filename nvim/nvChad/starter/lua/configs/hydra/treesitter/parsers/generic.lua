local M = {}
local supported_nodes = require("configs.hydra.treesitter.lib.constants").supported_nodes

-- Fallback parse result
function M.parse_generic(node_info)
  return {
    node_kind = supported_nodes.generic,
    role = node_info.node_type,
    display_name = node_info.node_type,
    cursor_node_type = node_info.node_type,
    summary = {},
  }
end

return M
