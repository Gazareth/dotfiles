local M = {}
local supported_nodes = require("configs.nui.treesitter.lib.constants").supported_nodes

-- Return a binary-expression-specific parse result.
function M.parse_binary_expression(node_info)
  return {
    node_kind = supported_nodes.binary_expression,
    role = "binary expression",
    display_name = "binary expression",
    summary = {
      parent_type = node_info.parent_type,
      text = node_info.text,
    },
  }
end

return M