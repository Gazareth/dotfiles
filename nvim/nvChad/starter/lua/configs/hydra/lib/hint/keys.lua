local M = {}

-- Default order for auto-assigned keys when a declared key is already taken. Override via
-- `hint.build(..., { hotkey_pool = "..." })` or Atlantis `open({ hotkey_pool = "..." })`.
M.DEFAULT_HOTKEY_POOL = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

-- Digits, then lower, then upper — each character is its own Hydra head (u ≠ U in Normal).
-- For modifier spelling you can use lhs strings like "<S-u>" in schema; in nmode that is the
-- same physical key as "U", so pick one form and treat it as one slot in `used`.

local function clone_item(item)
  return vim.tbl_extend("force", {}, item)
end

function M.normalize_sections(sections, opts)
  opts = opts or {}
  local pool = (type(opts.hotkey_pool) == "string" and opts.hotkey_pool ~= "") and opts.hotkey_pool
    or M.DEFAULT_HOTKEY_POOL

  local function next_hotkey(used)
    for char in pool:gmatch(".") do
      if not used[char] then
        used[char] = true
        return char
      end
    end
    return nil
  end

  local normalized = {}
  local used = { q = true }

  for index = 1, 3 do
    local section = sections[index] or { title = "", items = {} }
    local rows = {}

    for _, raw_item in ipairs(section.items or {}) do
      local item = clone_item(raw_item)

      if type(item.key) == "string" and item.key ~= "" then
        local key = item.key
        if used[key] then
          key = next_hotkey(used)
        else
          used[key] = true
        end

        if key ~= nil then
          item._resolved_key = key
          rows[#rows + 1] = item
        end
      else
        rows[#rows + 1] = item
      end
    end

    normalized[index] = {
      title = section.title or "",
      items = rows,
    }
  end

  return normalized
end

return M
