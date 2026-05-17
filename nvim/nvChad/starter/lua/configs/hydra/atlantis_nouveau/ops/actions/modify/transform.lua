local M = {}

function M.run(result)
  local ok, tna = pcall(require, "ts-node-action")
  if not ok then return end
  local r = result.range
  if not r then return end
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
  tna.node_action()
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({ bufnr = result.bufnr })
  end)
end

return M
