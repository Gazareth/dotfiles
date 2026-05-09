return function(result)
  if result.range then
    local r = result.range
    local lines = vim.api.nvim_buf_get_text(
      result.bufnr, r.start_row, r.start_col, r.end_row, r.end_col, {}
    )
    local text = table.concat(lines, "\n")

    -- Set the unnamed register and the yank register (0)
    -- We use 'v' for charwise to match Tree-sitter's precise ranges.
    vim.fn.setreg('"', text, 'v')
    vim.fn.setreg('0', text, 'v')

    -- If clipboard is set to unnamed or unnamedplus, also set the system clipboard
    local cb = vim.o.clipboard
    if cb:find("unnamed") then
      vim.fn.setreg('*', text, 'v')
    end
    if cb:find("unnamedplus") then
      vim.fn.setreg('+', text, 'v')
    end

    vim.notify("[atlantis] yanked to register", vim.log.levels.INFO)
  end
end
