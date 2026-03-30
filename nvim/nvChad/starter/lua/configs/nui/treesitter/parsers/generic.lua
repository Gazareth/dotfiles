local M = {}
local supported_nodes = require("configs.nui.treesitter.lib.constants").supported_nodes

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