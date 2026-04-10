local M = {}

-- Open Atlantis at a target using the requested depth mode
function M.navigate_and_open_at_depth(target, depth)
  if not target or not target.bufnr or not depth then
    return function() end
  end

  return function()
    local Menu = require("configs.hydra.common.menu")
    local atlantis = require("configs.hydra.atlantis")

    -- Focus target buffer before moving the cursor
    if target.bufnr and vim.api.nvim_buf_is_valid(target.bufnr) then
      vim.api.nvim_set_current_buf(target.bufnr)
    end

    -- Move cursor and center view on the target location
    if type(target.row) == "number" and type(target.col) == "number" then
      vim.api.nvim_win_set_cursor(0, { target.row + 1, target.col })
      vim.cmd("normal! zz")
    end

    -- Open menu using the provided anchor depth mode
    Menu.open(atlantis.build_menu_spec({
      depth_mode = depth,
    }))
  end
end

return M
