local M = {}

function M.switch_to_comment(result)
  local cr = result.comment_range
  if not cr then return end
  vim.api.nvim_win_set_cursor(0, { cr.start_row + 1, cr.start_col })
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({ bufnr = result.bufnr })
  end)
end

function M.switch_to_statement(result)
  local st = result.associated_statement
  if not st then return end
  local r = st.range
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({
      bufnr            = result.bufnr,
      target_node_type = st.node_type,
      target_start_row = r.start_row,
      target_start_col = r.start_col,
    })
  end)
end

return M
