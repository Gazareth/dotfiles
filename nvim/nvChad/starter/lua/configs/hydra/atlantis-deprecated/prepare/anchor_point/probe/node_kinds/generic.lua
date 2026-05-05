local M = {}
local supported_nodes = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.constants").supported_nodes

-- Build fallback parse payload for unsupported probe node types
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
