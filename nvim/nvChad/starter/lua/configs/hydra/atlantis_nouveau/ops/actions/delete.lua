return function(result)
  if result.range then
    local r = result.range
    -- Yank first (to match Vim behavior)
    local lines = vim.api.nvim_buf_get_text(
      result.bufnr, r.start_row, r.start_col, r.end_row, r.end_col, {}
    )
    local text = table.concat(lines, "\n")
    vim.fn.setreg('"', text, 'v')
    vim.fn.setreg('0', text, 'v')

    -- Delete the precise range
    vim.api.nvim_buf_set_text(
      result.bufnr,
      r.start_row,
      r.start_col,
      r.end_row,
      r.end_col,
      {}
    )
  end
end
