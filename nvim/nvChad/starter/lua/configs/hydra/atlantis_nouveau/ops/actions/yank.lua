return function(result)
  if result.range then
    local r = result.range
    local lines = vim.api.nvim_buf_get_text(
      result.bufnr, r.start_row, r.start_col, r.end_row, r.end_col, {}
    )
    local text = table.concat(lines, "\n")
    vim.fn.setreg('"', text)
    vim.notify("[atlantis] yanked", vim.log.levels.INFO)
  end
end
