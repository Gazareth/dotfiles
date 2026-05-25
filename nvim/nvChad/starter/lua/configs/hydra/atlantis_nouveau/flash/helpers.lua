local M = {}

local HINT_TEXT = " [?] Toggle hint   [<S-Tab>/<Tab>] Cycle selection mode   [q]/[Esc] Exit "

function M.open_hint_win()
  local width = vim.api.nvim_strwidth(HINT_TEXT)
  local row   = math.max(0, vim.o.lines - vim.o.cmdheight - 3)
  local col   = math.max(0, math.floor((vim.o.columns - width) / 2))
  local buf   = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { HINT_TEXT })
  local win = vim.api.nvim_open_win(buf, false, {
    relative  = "editor",
    row       = row,
    col       = col,
    width     = width,
    height    = 1,
    style     = "minimal",
    border    = "rounded",
    focusable = false,
    zindex    = 50,
  })
  return win, buf
end

function M.close_hint_win(win, buf)
  pcall(vim.api.nvim_win_close, win, true)
  pcall(vim.api.nvim_buf_delete, buf, { force = true })
end

function M.do_jump(bufnr, item)
  local range = item.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({
      bufnr            = bufnr,
      target_node_type = item.node_type,
      target_start_row = range.start_row,
      target_start_col = range.start_col,
      mode             = "flash",
    })
  end)
end

return M
