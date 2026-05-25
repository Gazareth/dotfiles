local M = {}

local targets_mod = require("configs.hydra.atlantis_nouveau.flash.targets")
local actions_mod = require("configs.hydra.atlantis_nouveau.flash.actions")
local helpers     = require("configs.hydra.atlantis_nouveau.flash.helpers")

vim.keymap.set("n", "<Plug>(AtlantisJump)", function()
  local result = M._pending
  M._pending   = nil
  if not result then return end

  local bufnr   = result.bufnr
  local cleanup = result._highlight_cleanup
  local win     = vim.api.nvim_get_current_win()
  local targets = targets_mod.collect(result, win)
  local nav     = result.navigation or {}

  local plugins = require("configs.hydra.atlantis_nouveau.plugins")

  local state = {
    nav_item          = nil,
    pending_action    = nil,
    tab_pressed       = false,
    shift_tab_pressed = false,
    hint_win          = nil,
    hint_buf          = nil,
  }

  local actions = actions_mod.build(nav, result, plugins, state)

  if #targets == 0 and next(actions) == nil then
    if cleanup then cleanup() end
    vim.notify("[atlantis] No jump targets at this location", vim.log.levels.INFO)
    return
  end

  state.hint_win, state.hint_buf = helpers.open_hint_win()

  local action_called = false

  require("flash").jump({
    search    = { enabled = false },
    highlight = { matches = false },
    labels    = targets_mod.LABEL_POOL,
    label     = { style = "overlay", after = false, before = true },
    matcher   = function() return targets end,
    labeler   = function(matches, _s)
      for _, match in ipairs(matches) do
        match.label = match._my_label
      end
    end,
    actions = actions,
    action  = function(match, s)
      action_called = true
      s:hide()
      helpers.close_hint_win(state.hint_win, state.hint_buf)
      helpers.do_jump(bufnr, match._item)
    end,
  })

  if state.tab_pressed then
    helpers.close_hint_win(state.hint_win, state.hint_buf)
    vim.schedule(function()
      -- No children: skip namu and continue forwards to standard.
      local mode = (result.outline and #result.outline > 0) and "namu" or "standard"
      require("configs.hydra.atlantis_nouveau").open({
        bufnr            = bufnr,
        target_node_type = result.node_type,
        target_start_row = result.range.start_row,
        target_start_col = result.range.start_col,
        mode             = mode,
      })
    end)
  elseif state.shift_tab_pressed then
    helpers.close_hint_win(state.hint_win, state.hint_buf)
    vim.schedule(function()
      require("configs.hydra.atlantis_nouveau").open({
        bufnr            = bufnr,
        target_node_type = result.node_type,
        target_start_row = result.range.start_row,
        target_start_col = result.range.start_col,
        mode             = "standard",
      })
    end)
  elseif state.pending_action then
    helpers.close_hint_win(state.hint_win, state.hint_buf)
    if cleanup then cleanup() end
    state.pending_action()
  elseif state.nav_item then
    helpers.close_hint_win(state.hint_win, state.hint_buf)
    helpers.do_jump(bufnr, state.nav_item)
  elseif not action_called then
    -- Esc/q: clear the highlight (no Atlantis reopen to do it for us).
    if cleanup then cleanup() end
    helpers.close_hint_win(state.hint_win, state.hint_buf)
  end
end)

function M.open(result)
  -- Update remembered mode here because this can be called directly from the
  -- Tab head in menu/init.lua, bypassing init.lua's controlled setter.
  require("configs.hydra.atlantis_nouveau")._mode = "flash"
  -- <Plug> indirection is needed because flash.jump() must run outside of a
  -- fast event (keymap callbacks from Hydra are fast); feedkeys defers it.
  M._pending = result
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Plug>(AtlantisJump)", true, false, true),
    "n", false
  )
end

return M
