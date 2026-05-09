local M = {}

--- Selects the given range in visual mode and executes the provided keys.
--- @param result table The Atlantis result object containing the range and bufnr.
--- @param keys string The keys to execute (e.g., "y", "d", "c", "X").
--- @param opts table? Optional table with:
---   - remap (boolean): Whether to use 'normal' instead of 'normal!' (default false).
---   - mode (string): Visual mode type ('v', 'V', or '<C-v>', default 'v').
---   - enter_insert (boolean): Whether to call startinsert after the action (default false).
function M.run_on_range(result, keys, opts)
  opts = opts or {}
  local r = result.range
  if not r then return end

  -- Move cursor to start of the node
  vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })

  -- Programmatically enter visual mode
  local mode = opts.mode or "v"
  vim.cmd("normal! " .. mode)

  -- Move to end of the node (end_col is exclusive, so we go to end_col - 1)
  vim.api.nvim_win_set_cursor(0, { r.end_row + 1, math.max(0, r.end_col - 1) })

  -- Trigger the keys
  if keys and keys ~= "" then
    if opts.remap then
      vim.cmd("normal " .. keys)
    else
      vim.cmd("normal! " .. keys)
    end

    -- If requested, explicitly enter insert mode (useful for 'change' operations)
    if opts.enter_insert then
      vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
      vim.cmd("startinsert")
    end
  end
end

return M
