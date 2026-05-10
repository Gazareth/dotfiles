local M = {}

local function jump_and_reopen(bufnr, target)
  if not target then return end
  local range = target.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open(
      bufnr, nil,
      target.node_type, range.start_row, range.start_col
    )
  end)
end

local function same_target(a, b)
  if not a or not b then return false end
  return a.range.start_row == b.range.start_row and a.range.start_col == b.range.start_col
end

local function format_range(r)
  return string.format("(%d:%d-%d:%d)", r.start_row + 1, r.start_col, r.end_row + 1, r.end_col)
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
    if nav.nearest_function
       and not same_target(nav.nearest_function, nav.parent)
       and not same_target(nav.nearest_function, nav.nearest_body) then
      table.insert(context_items, {
        key    = "f",
        icon   = "󰜷",
        label  = "to function",
        action = function() jump_and_reopen(result.bufnr, nav.nearest_function) end,
      })
    end
    if nav.nearest_body and not same_target(nav.nearest_body, nav.parent) then
      table.insert(context_items, {
        key    = "b",
        icon   = "󰜷",
        label  = "to body",
        action = function() jump_and_reopen(result.bufnr, nav.nearest_body) end,
      })
    end
    if nav.parent then
      local p = nav.parent
      local class = p.classification ~= "" and p.classification or "Node"
      
      table.insert(context_items, {
        key    = "h",
        icon   = "󰜷",
        label  = string.format("to parent [%s %s]", class, format_range(p.range)),
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
