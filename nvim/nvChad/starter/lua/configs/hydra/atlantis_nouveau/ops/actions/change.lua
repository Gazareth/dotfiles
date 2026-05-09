return function(result)
  local r = result.range
  if not r then return end

  -- Yank first
  local lines = vim.api.nvim_buf_get_text(
    result.bufnr, r.start_row, r.start_col, r.end_row, r.end_col, {}
  )
  local text = table.concat(lines, "\n")
  vim.fn.setreg('"', text, 'v')
  vim.fn.setreg('0', text, 'v')

  -- Clear the range text
  vim.api.nvim_buf_set_text(
    result.bufnr,
    r.start_row,
    r.start_col,
    r.end_row,
    r.end_col,
    { "" }
  )

  -- Move cursor to the start of the cleared range and enter insert mode
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
  vim.cmd("startinsert")
end
