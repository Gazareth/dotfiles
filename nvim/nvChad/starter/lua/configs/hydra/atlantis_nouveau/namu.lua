local M = {}
local highlight_node = require("configs.hydra.atlantis_nouveau.menu.highlight_node")

function M.open(result)
  -- Update remembered mode here because this can be called directly from the
  -- overflow Tab head in menu/init.lua, bypassing init.lua's controlled setter.
  require("configs.hydra.atlantis_nouveau")._mode = "namu"

  local bufnr = result.bufnr
  local items = {}
  for _, item in ipairs(result.outline or {}) do
    items[#items + 1] = { text = item.label or item.node_type or "?", value = item }
  end

  if #items == 0 then
    vim.notify("[atlantis] No namu targets at this location", vim.log.levels.INFO)
    return
  end

  local orig_win    = vim.api.nvim_get_current_win()
  local cleanup     = highlight_node.apply(bufnr, result.range)
  local tab_pressed       = false
  local shift_tab_pressed = false
  local jumped            = false

  require("namu.selecta.selecta").pick(items, {
    title = "Children",
    fuzzy = true,
    custom_keymaps = {
      {
        keys    = "<Tab>",
        handler = function()
          tab_pressed = true
          return true  -- close picker, triggers on_close
        end,
      },
      {
        keys    = "<S-Tab>",
        handler = function()
          shift_tab_pressed = true
          return true
        end,
      },
    },
    on_move = function(selected)
      if not selected then return end
      local item = selected.value
      if item and item.range then
        vim.api.nvim_win_set_cursor(orig_win, { item.range.start_row + 1, item.range.start_col })
        vim.api.nvim_win_call(orig_win, function() vim.cmd("normal! zz") end)
        highlight_node.update(bufnr, item.range)
      end
    end,
    on_select = function(selected)
      if not selected then return end
      jumped = true
      local item  = selected.value
      local range = item.range
      vim.api.nvim_win_set_cursor(orig_win, { range.start_row + 1, range.start_col })
      vim.api.nvim_win_call(orig_win, function() vim.cmd("normal! zz") end)
      -- highlight_node.apply() in the next open() call clears this highlight.
      vim.schedule(function()
        require("configs.hydra.atlantis_nouveau").open({
          bufnr            = bufnr,
          target_node_type = item.node_type,
          target_start_row = range.start_row,
          target_start_col = range.start_col,
          -- mode = nil: uses remembered "namu"
        })
      end)
    end,
    -- on_cancel is NOT called when a custom_keymap handler returns true; use
    -- on_close (always fires) and distinguish cases via flags.
    on_close = function()
      if tab_pressed then
        tab_pressed = false
        vim.schedule(function()
          require("configs.hydra.atlantis_nouveau").open({
            bufnr            = bufnr,
            target_node_type = result.node_type,
            target_start_row = result.range.start_row,
            target_start_col = result.range.start_col,
            mode             = "standard",
          })
        end)
      elseif shift_tab_pressed then
        shift_tab_pressed = false
        vim.schedule(function()
          require("configs.hydra.atlantis_nouveau").open({
            bufnr            = bufnr,
            target_node_type = result.node_type,
            target_start_row = result.range.start_row,
            target_start_col = result.range.start_col,
            mode             = "flash",
          })
        end)
      elseif not jumped then
        -- Esc with no jump: clear the highlight ourselves.
        cleanup()
      end
      -- If jumped: highlight_node.apply() in the next open() call clears it.
    end,
  })
end

return M
