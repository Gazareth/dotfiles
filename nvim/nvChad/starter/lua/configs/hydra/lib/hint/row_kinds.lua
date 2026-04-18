-- Hydra hint row kinds: one renderer per discriminated item shape (ordered chain).
-- Adding a kind: append a predicate/renderer that returns a string when it handles the item,
-- or nil when it declines (next handler runs).

local hint_row_kinds = {}

local function keyed_action_line(item)
  if type(item._resolved_key) ~= "string" or item._resolved_key == "" then
    return nil
  end
  local icon = item.icon or ""
  local label = item.label or ""
  local key_show = (type(item._hint_key_display) == "string" and item._hint_key_display ~= "")
      and item._hint_key_display
    or item._resolved_key
  return string.format("[%s] %s %s", key_show, icon, label)
end

local function labeled_separator(item)
  if not item.separator then
    return nil
  end
  if type(item.label) == "string" and item.label ~= "" then
    return "--- " .. item.label .. " ---"
  end
  return nil
end

local function bare_separator(item)
  if item.separator then
    return ""
  end
  return nil
end

local function heading(item)
  if type(item.heading) == "string" and item.heading ~= "" then
    return "== " .. item.heading .. " =="
  end
  return nil
end

local function plain_label(item)
  return item.label or ""
end

-- Order matters: first matching handler wins.
local chain = {
  labeled_separator,
  bare_separator,
  heading,
  keyed_action_line,
  plain_label,
}

--- @param item table hint row descriptor (separator | heading | keyed | plain)
function hint_row_kinds.render(item)
  for _, fn in ipairs(chain) do
    local rendered = fn(item)
    if rendered ~= nil then
      return rendered
    end
  end
  return ""
end

return hint_row_kinds
