local M = {}

-- Nav items in display order; keys are also registered as Flash actions so they
-- work regardless of label visibility.
local NAV_ORDER = {
  { key = "H", field = "top_level"        },
  { key = "F", field = "nearest_function" },
  { key = "B", field = "nearest_body"     },
  { key = "h", field = "parent"           },
  { key = "j", field = "prev_sibling"     },
  { key = "k", field = "next_sibling"     },
}

-- Flash doesn't auto-assign labels when search is disabled, so we own the full
-- label assignment. Pool excludes nav keys and common hint_key chars (l, r, p).
local LABEL_POOL = "asdfgwetuyiozxcvbnm1234567890"

-- Flash uses (1,0)-indexed positions: 1-indexed row, 0-indexed col.
local function collect_targets(result, win)
  local nav = result.navigation or {}

  -- ── Pass 1a: group nav items by position ────────────────────────────────
  local nav_by_pos   = {}
  local nav_pos_list = {}

  for _, entry in ipairs(NAV_ORDER) do
    -- H is skipped as a label when already at top (points to current position).
    -- It still registers as a Flash action via build_nav_actions.
    if entry.field == "top_level" and nav.is_at_top then
      -- skip label, keep action
    else
      local item = nav[entry.field]
      if item and item.range then
        local pk = item.range.start_row .. ":" .. item.range.start_col
        if not nav_by_pos[pk] then
          nav_by_pos[pk] = { item = item, keys = {} }
          table.insert(nav_pos_list, pk)
        end
        table.insert(nav_by_pos[pk].keys, entry.key)
      end
    end
  end

  -- ── Pass 1b: collect all pinned labels so pool assignment avoids them ────
  local used = {}

  for _, pk in ipairs(nav_pos_list) do
    for _, k in ipairs(nav_by_pos[pk].keys) do used[k] = true end
  end

  local outline  = result.outline or {}
  local seen_pos = {}
  for _, pk in ipairs(nav_pos_list) do seen_pos[pk] = true end

  local first_outline_idx = nil
  for i, item in ipairs(outline) do
    if item.range then
      local pk = item.range.start_row .. ":" .. item.range.start_col
      if not seen_pos[pk] then
        local hint = (type(item.hint_key) == "string" and item.hint_key ~= "") and item.hint_key or nil
        if hint then
          used[hint] = true
        elseif first_outline_idx == nil then
          first_outline_idx = i
          used["l"] = true
        end
      end
    end
  end

  -- Comment/statement switch target: always pinned to "%".
  local switch_item = result.comment_range and { range = result.comment_range }
                   or result.associated_statement
  if switch_item then used["%"] = true end

  -- ── Pool iterator: yields unused labels in LABEL_POOL order ─────────────
  local pool_i = 1
  local function next_label()
    while pool_i <= #LABEL_POOL do
      local c = LABEL_POOL:sub(pool_i, pool_i)
      pool_i = pool_i + 1
      if not used[c] then
        used[c] = true
        return c
      end
    end
  end

  -- ── Pass 2: build target list with explicit labels ───────────────────────
  local targets = {}

  for _, pk in ipairs(nav_pos_list) do
    local data = nav_by_pos[pk]
    local p    = { data.item.range.start_row + 1, data.item.range.start_col }
    targets[#targets + 1] = {
      win       = win,
      pos       = p,
      end_pos   = p,
      _item     = data.item,
      _my_label = table.concat(data.keys, "/"),
    }
  end

  if switch_item then
    local pk = switch_item.range.start_row .. ":" .. switch_item.range.start_col
    if not seen_pos[pk] then
      seen_pos[pk] = true
      local p = { switch_item.range.start_row + 1, switch_item.range.start_col }
      targets[#targets + 1] = {
        win       = win,
        pos       = p,
        end_pos   = p,
        _item     = switch_item,
        _my_label = "%",
      }
    end
  end

  for i, item in ipairs(outline) do
    if item.range then
      local pk = item.range.start_row .. ":" .. item.range.start_col
      if not seen_pos[pk] then
        seen_pos[pk] = true
        local hint  = (type(item.hint_key) == "string" and item.hint_key ~= "") and item.hint_key or nil
        local label = hint or (i == first_outline_idx and "l" or next_label())
        local p     = { item.range.start_row + 1, item.range.start_col }
        targets[#targets + 1] = {
          win       = win,
          pos       = p,
          end_pos   = p,
          _item     = item,
          _my_label = label,
        }
      end
    end
  end

  return targets
end

-- Register each individual nav key as a Flash action so pressing "j" or "B"
-- always works, even when they share a combined label with another key.
local function build_nav_actions(nav, on_nav)
  local actions = {}
  for _, entry in ipairs(NAV_ORDER) do
    local target = nav[entry.field]
    if target then
      actions[entry.key] = function(_state, _char)
        on_nav(target)
        return false
      end
    end
  end
  return actions
end

local function open_hint_win()
  local text = " [?] Toggle hint   [<Tab>] Cycle selection mode   [q]/[Esc] Exit "
  local width = vim.api.nvim_strwidth(text)
  local row   = math.max(0, vim.o.lines - vim.o.cmdheight - 3)
  local col   = math.max(0, math.floor((vim.o.columns - width) / 2))
  local buf   = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
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

local function close_hint_win(win, buf)
  pcall(vim.api.nvim_win_close, win, true)
  pcall(vim.api.nvim_buf_delete, buf, { force = true })
end

local function do_jump(bufnr, item)
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

vim.keymap.set("n", "<Plug>(AtlantisJump)", function()
  local result = M._pending
  M._pending   = nil
  if not result then return end

  local bufnr   = result.bufnr
  local cleanup = result._highlight_cleanup
  local win     = vim.api.nvim_get_current_win()
  local targets = collect_targets(result, win)
  local nav     = result.navigation or {}

  local nav_item = nil
  local actions  = build_nav_actions(nav, function(t) nav_item = t end)

  local switch_item = result.comment_range and { range = result.comment_range }
                   or result.associated_statement
  if switch_item then
    actions["%"] = function(_state, _char)
      nav_item = switch_item
      return false
    end
  end

  local has_nav  = next(actions) ~= nil

  if #targets == 0 and not has_nav then
    if cleanup then cleanup() end
    vim.notify("[atlantis] No jump targets at this location", vim.log.levels.INFO)
    return
  end

  local hint_win, hint_buf = open_hint_win()

  local action_called = false
  local tab_pressed   = false

  actions["<Tab>"] = function(_state, _char)
    tab_pressed = true
    return false
  end

  require("flash").jump({
    search    = { enabled = false },
    highlight = { matches = false },
    labels    = LABEL_POOL,
    label     = { style = "overlay", after = false, before = true },
    matcher   = function() return targets end,
    labeler   = function(matches, _state)
      for _, match in ipairs(matches) do
        match.label = match._my_label
      end
    end,
    actions = actions,
    action  = function(match, state)
      action_called = true
      state:hide()
      close_hint_win(hint_win, hint_buf)
      do_jump(bufnr, match._item)
    end,
  })

  if tab_pressed then
    close_hint_win(hint_win, hint_buf)
    vim.schedule(function()
      require("configs.hydra.atlantis_nouveau").open({
        bufnr            = bufnr,
        target_node_type = result.node_type,
        target_start_row = result.range.start_row,
        target_start_col = result.range.start_col,
        mode             = "namu",
      })
    end)
  elseif nav_item then
    close_hint_win(hint_win, hint_buf)
    do_jump(bufnr, nav_item)
  elseif not action_called then
    -- Esc: clear the highlight (no Atlantis reopen to do it for us).
    if cleanup then cleanup() end
    close_hint_win(hint_win, hint_buf)
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
