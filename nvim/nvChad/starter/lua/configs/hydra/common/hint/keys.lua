local M = {}

local HOTKEY_POOL = "1234567890abcdefghijklmnopqrstuvwxyz"

local function next_hotkey(used)
  for char in HOTKEY_POOL:gmatch(".") do
    if not used[char] then
      used[char] = true
      return char
    end
  end
  return nil
end

local function clone_item(item)
  return vim.tbl_extend("force", {}, item)
end

function M.normalize_sections(sections)
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
