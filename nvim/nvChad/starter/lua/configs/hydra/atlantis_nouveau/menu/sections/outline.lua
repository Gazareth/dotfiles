local M = {}

local KEYS = { "1","2","3","4","5","6","7","8","9",
               "a","c","e","f","g","h","i","j","k","l","m",
               "n","o","q","r","s","t","u","v","w","x","z" }

local function jump_to_item(bufnr, item)
  local range = item.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open(
      bufnr, nil,
      item.node_type, range.start_row, range.start_col
    )
  end)
end

function M.build(result)
  local items = result.outline
  if not items or #items == 0 then return nil end

  -- Collect hint keys declared by the Rust side so we can exclude them from the pool.
  local hinted = {}
  for _, item in ipairs(items) do
    if item.hint_key then hinted[item.hint_key] = true end
  end

  -- Build the sequential fallback pool, excluding any hint keys.
  local pool = {}
  for _, k in ipairs(KEYS) do
    if not hinted[k] then pool[#pool + 1] = k end
  end

  local pool_idx = 1
  local rows = {}
  for _, item in ipairs(items) do
    local key
    if item.hint_key then
      key = item.hint_key
    else
      key = pool[pool_idx]
      pool_idx = pool_idx + 1
    end
    rows[#rows + 1] = {
      key    = key,
      label  = item.label,
      action = function() jump_to_item(result.bufnr, item) end,
    }
  end

  return { title = "Contents", items = rows }
end

return M
