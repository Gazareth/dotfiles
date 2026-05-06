local M = {}

local ns               = vim.api.nvim_create_namespace("atlantis_highlight")
local open_count       = 0
local saved_cursorline = nil

-- Default highlight — override by defining AtlantisHL in your config or colorscheme:
--   vim.api.nvim_set_hl(0, "AtlantisHL", { bg = "#3d4220" })
vim.api.nvim_set_hl(0, "AtlantisHL", { link = "Visual", default = true })

--- Apply a transient highlight over [r.start_row..r.end_row] in bufnr.
--- Returns an on_exit callback to pass to the Hydra spec; it clears the
--- highlight and restores cursorline on genuine final exit (not sibling nav).
function M.apply(bufnr, r)
  open_count = open_count + 1
  local my_count = open_count

  if bufnr then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end

  -- Set the extmark synchronously so it is present before make_hydra.open
  -- draws the hint window; no Hydra restore will remove buffer extmarks.
  if bufnr and r then
    vim.api.nvim_buf_set_extmark(bufnr, ns, r.start_row, r.start_col, {
      end_row  = r.end_row,
      end_col  = r.end_col,
      hl_group = "AtlantisHL",
      priority = 4096,
    })
  end

  if saved_cursorline == nil then
    saved_cursorline = vim.wo.cursorline
  end

  -- Defer cursorline only — must run after any outer Hydra's options:restore().
  vim.schedule(function()
    vim.wo.cursorline = false
  end)

  return function()
    if open_count == my_count then
      if saved_cursorline ~= nil then
        vim.wo.cursorline = saved_cursorline
        saved_cursorline  = nil
      end
      if bufnr then
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      end
    end
  end
end

return M
