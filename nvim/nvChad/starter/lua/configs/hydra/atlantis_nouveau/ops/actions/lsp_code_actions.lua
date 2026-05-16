local M = {}

function M.run(result)
  local r = result.range
  if not r then
    vim.lsp.buf.code_action()
    return
  end
  vim.lsp.buf.code_action({
    range = {
      start   = { r.start_row + 1, r.start_col },
      ["end"] = { r.end_row + 1,   r.end_col   },
    },
  })
end

return M
