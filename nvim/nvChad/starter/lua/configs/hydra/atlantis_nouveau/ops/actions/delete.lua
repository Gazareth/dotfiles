return function(result)
  local range = result.range
  if not range then return end
  -- Delete from start_row to end_row (inclusive), 0-based
  vim.api.nvim_buf_set_lines(
    result.bufnr,
    range.start_row,
    range.end_row + 1,
    false,
    {}
  )
end
