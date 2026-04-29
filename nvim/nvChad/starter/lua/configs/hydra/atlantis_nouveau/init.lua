local surveyor = require("atlantis_surveyor")
local menu     = require("configs.hydra.atlantis_nouveau.menu")

local M = {}

function M.open(bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  row = row or (cursor[1] - 1)  -- nvim cursor is 1-based; surveyor expects 0-based
  col = col or cursor[2]

  local result = surveyor.node(bufnr, row, col)

  if result.variant.kind == "error" then
    vim.notify("[atlantis] " .. result.variant.message, vim.log.levels.WARN)
    return
  end

  if result.variant.kind == "unrecognised" or not result.available_actions or #result.available_actions == 0 then
    vim.notify("[atlantis] nothing here", vim.log.levels.INFO)
    return
  end

  menu.open(result)
end

return M
