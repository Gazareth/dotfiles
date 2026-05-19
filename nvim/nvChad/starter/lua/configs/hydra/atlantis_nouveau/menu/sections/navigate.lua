local M = {}
local badge = require("configs.hydra.atlantis_nouveau.menu.badge")

-- Nav key→field mapping shared with flash.lua so both modes stay in sync.
M.nav_order = {
  { key = "H", field = "top_level"        },
  { key = "F", field = "nearest_function" },
  { key = "B", field = "nearest_body"     },
  { key = "h", field = "parent"           },
  { key = "j", field = "next_sibling"     },
  { key = "k", field = "prev_sibling"     },
}

local function jump_and_reopen(bufnr, target)
  if not target then return end
  local range = target.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({
      bufnr            = bufnr,
      target_node_type = target.node_type,
      target_start_row = range.start_row,
      target_start_col = range.start_col,
    })
  end)
end

local function same_target(a, b)
  if not a or not b then return false end
  return a.range.start_row == b.range.start_row and a.range.start_col == b.range.start_col
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
      label     = "top level  (" .. badge.short(nav.top_level) .. ")",
      action    = function() jump_and_reopen(result.bufnr, nav.top_level) end,
    })
  else
    if nav.top_level then
      table.insert(context_items, {
        key    = "H",
        icon   = "󰜸",
        label  = "top level  (" .. badge.short(nav.top_level) .. ")",
        action = function() jump_and_reopen(result.bufnr, nav.top_level) end,
      })
    end
    if nav.nearest_function
       and not same_target(nav.nearest_function, nav.parent)
       and not same_target(nav.nearest_function, nav.nearest_body) then
      table.insert(context_items, {
        key    = "F",
        icon   = "󰜷",
        label  = "function  (" .. badge.short(nav.nearest_function) .. ")",
        action = function() jump_and_reopen(result.bufnr, nav.nearest_function) end,
      })
    end
    if nav.nearest_body and not same_target(nav.nearest_body, nav.parent) then
      table.insert(context_items, {
        key    = "B",
        icon   = "󰜷",
        label  = "body  (" .. badge.short(nav.nearest_body) .. ")",
        action = function() jump_and_reopen(result.bufnr, nav.nearest_body) end,
      })
    end
    if nav.parent then
      table.insert(context_items, {
        key    = "h",
        icon   = "󰜷",
        label  = "parent  (" .. badge.short(nav.parent) .. ")",
        action = function() jump_and_reopen(result.bufnr, nav.parent) end,
      })
    end
  end

  if result.outline and #result.outline > 0 then
    local child = result.outline[1]
    table.insert(context_items, {
      key    = "l",
      icon   = "󰜴",
      label  = "child  (" .. badge.short(child) .. ")",
      action = function() jump_and_reopen(result.bufnr, child) end,
    })
  end

  if #context_items > 0 then
    table.insert(items, { heading = "Context" })
    for _, item in ipairs(context_items) do
      table.insert(items, item)
    end
  end

  -- Siblings sub-section (always shown; notifies when no sibling is available)
  table.insert(items, { heading = "Siblings" })
  table.insert(items, {
    key    = "k",
    icon   = "󰜶",
    label  = nav.prev_sibling and ("previous  (" .. badge.short(nav.prev_sibling) .. ")") or "no sibling",
    action = nav.prev_sibling
      and function() jump_and_reopen(result.bufnr, nav.prev_sibling) end
      or  function()
            vim.notify("No sibling — use h to jump to parent.", vim.log.levels.INFO)
          end,
  })
  table.insert(items, {
    key    = "j",
    icon   = "󰜴",
    label  = nav.next_sibling and ("next  (" .. badge.short(nav.next_sibling) .. ")") or "no sibling",
    action = nav.next_sibling
      and function() jump_and_reopen(result.bufnr, nav.next_sibling) end
      or  function()
            vim.notify("No sibling — use h to jump to parent.", vim.log.levels.INFO)
          end,
  })

  if #items == 0 then return nil end

  return { title = "Navigate", items = items }
end

return M
