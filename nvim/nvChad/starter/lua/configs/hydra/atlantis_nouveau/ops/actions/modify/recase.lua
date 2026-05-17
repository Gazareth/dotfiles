local M = {}

local cases = {
  { label = "camelCase",   cmd = "gsc" },
  { label = "PascalCase",  cmd = "gsp" },
  { label = "snake_case",  cmd = "gs_" },
  { label = "UPPER_SNAKE", cmd = "gsU" },
  { label = "kebab-case",  cmd = "gsk" },
  { label = "Title Case",  cmd = "gst" },
}

function M.run(result)
  local labels = vim.tbl_map(function(c) return c.label end, cases)
  vim.ui.select(labels, { prompt = "Re-case to:" }, function(choice)
    if not choice then return end
    local r = result.range
    if not r then return end
    for _, c in ipairs(cases) do
      if c.label == choice then
        vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { r.end_row + 1, math.max(0, r.end_col - 1) })
        vim.cmd("normal " .. c.cmd)
        break
      end
    end
    vim.schedule(function()
      require("configs.hydra.atlantis_nouveau").open({ bufnr = result.bufnr })
    end)
  end)
end

return M
