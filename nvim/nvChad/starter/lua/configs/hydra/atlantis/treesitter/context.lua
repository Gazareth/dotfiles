local M = {}

-- Treesitter context payload
function M.build(node_info, parsed)
  return {
    node_info = node_info,
    parsed = parsed,
  }
end

return M
