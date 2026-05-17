local M = {}

function M.run(_result)
  vim.lsp.buf.code_action({
    filter = function(action)
      return action.title and action.title:lower():find("import") ~= nil
    end,
  })
end

return M
