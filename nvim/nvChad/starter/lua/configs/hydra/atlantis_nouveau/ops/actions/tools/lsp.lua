local M = {}

function M.run(result)
  local r = result.range
  vim.lsp.buf.code_action({
    range = r and {
      start   = { r.start_row + 1, r.start_col },
      ["end"] = { r.end_row + 1,   r.end_col   },
    } or nil,
  })
end

return M
