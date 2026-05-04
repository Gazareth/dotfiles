local M = {}

local function jump_and_reopen(bufnr, target)
  if not target then return end
  local range = target.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open(bufnr, target.target_mode)
  end)
end

function M.build(result)
  local nav = result.navigation
  if not nav then return nil end

  local items = {}

  -- Context sub-section
  local context_items = {}

  if nav.is_at_top then
    table.insert(context_items, {
      icon  = "󰜸",
      label = "Already at top level",
    })
  elseif nav.parent and nav.top_level and
         nav.parent.range.start_row == nav.top_level.range.start_row and
         nav.parent.range.start_col == nav.top_level.range.start_col then
    -- Merge H and h when they target the same node
    table.insert(context_items, {
      key       = "H",
      key_alias = "h",
      icon      = "󰜸",
      label     = "to top level",
      action    = function() jump_and_reopen(result.bufnr, nav.top_level) end,
    })
  else
    if nav.top_level then
      table.insert(context_items, {
        key    = "H",
        icon   = "󰜸",
        label  = "to top level",
        action = function() jump_and_reopen(result.bufnr, nav.top_level) end,
      })
    end
    if nav.parent then
      table.insert(context_items, {
        key    = "h",
        icon   = "󰜷",
        label  = "to parent",
        action = function() jump_and_reopen(result.bufnr, nav.parent) end,
      })
    end
  end

  if #context_items > 0 then
    table.insert(items, { heading = "Context" })
    for _, item in ipairs(context_items) do
      table.insert(items, item)
    end
  end

  -- Siblings sub-section
  local sibling_items = {}
  if nav.prev_sibling then
    table.insert(sibling_items, {
      key    = "u",
      icon   = "󰜶",
      label  = "to previous sibling",
      action = function() jump_and_reopen(result.bufnr, nav.prev_sibling) end,
    })
  end
  if nav.next_sibling then
    table.insert(sibling_items, {
      key    = "i",
      icon   = "󰜴",
      label  = "to next sibling",
      action = function() jump_and_reopen(result.bufnr, nav.next_sibling) end,
    })
  end

  if #sibling_items > 0 then
    table.insert(items, { heading = "Siblings" })
    for _, item in ipairs(sibling_items) do
      table.insert(items, item)
    end
  end

  if #items == 0 then return nil end

  return { title = "Navigate", items = items }
end

return M
