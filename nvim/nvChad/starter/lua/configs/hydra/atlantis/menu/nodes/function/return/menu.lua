local M = {}

-- Submenu for function return statements
function M.build(node_info, parsed)
  return {
    title = "Return",
    items = {
      {
        separator = true,
        label = "Return handling coming soon",
      },
    },
  }
end

return M
