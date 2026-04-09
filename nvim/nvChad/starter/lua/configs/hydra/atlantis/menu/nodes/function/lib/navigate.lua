local M = {}

-- Navigate cursor to target and open Atlantis menu at specified depth
function M.navigate_and_open_at_depth(target, depth)
  if not target or not target.bufnr or not depth then
    return function() end
  end

  return function()
    local Menu = require("configs.hydra.common.menu")
    local treesitter_config = require("configs.hydra.atlantis.treesitter.config")
    local atlantis = require("configs.hydra.atlantis")

    -- Position cursor at target
    if target.bufnr and vim.api.nvim_buf_is_valid(target.bufnr) then
      vim.api.nvim_set_current_buf(target.bufnr)
    end

    if type(target.row) == "number" and type(target.col) == "number" then
      vim.api.nvim_win_set_cursor(0, { target.row + 1, target.col })
      vim.cmd("normal! zz")
    end

    -- Open menu at specified depth
    treesitter_config.with_context_mode(depth, function()
      Menu.open(atlantis.build_menu_spec())
    end)
  end
end

return M
