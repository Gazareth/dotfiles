local M = {}

local NAV_ORDER = require("configs.hydra.atlantis_nouveau.menu.sections.navigate").nav_order

-- Excludes nav keys and common hint_key chars (l, r, p).
M.LABEL_POOL = "asdfgwetuyiozxcvbnm1234567890"

-- Flash uses (1,0)-indexed positions: 1-indexed row, 0-indexed col.
function M.collect(result, win)
  local nav = result.navigation or {}

  -- ── Pass 1a: group nav items by position ────────────────────────────────
  local nav_by_pos   = {}
  local nav_pos_list = {}

  for _, entry in ipairs(NAV_ORDER) do
    -- H is skipped as a label when already at top (points to current position).
    -- It still registers as a flash action via actions.build.
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

  -- Nav keys are pinned to their positions.
  for _, pk in ipairs(nav_pos_list) do
    for _, k in ipairs(nav_by_pos[pk].keys) do used[k] = true end
  end

  -- Mark action keys as used so they don't become labels
  local registry = require("configs.hydra.atlantis_nouveau.ops.registry")
  for _, op in ipairs(registry.action_ops) do
    used[op.key] = true
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
    while pool_i <= #M.LABEL_POOL do
      local c = M.LABEL_POOL:sub(pool_i, pool_i)
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

return M
