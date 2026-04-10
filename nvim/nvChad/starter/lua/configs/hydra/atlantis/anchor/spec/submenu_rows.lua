-- Build submenu rows from capability submenu specs while avoiding key collisions
local M = {}

-- Format submenu token into user-facing label text
local function format_submenu_label(token)
  local spaced = tostring(token or "submenu"):gsub("_", " ")
  return spaced:gsub("(%a)([%w_']*)", function(a, b)
    return string.upper(a) .. string.lower(b)
  end) .. "..."
end

-- Resolve submenu sort order with max fallback
local function get_submenu_order(spec)
  local order = type(spec) == "table" and spec.order or nil
  return type(order) == "number" and order or math.huge
end

-- Pick first unused key from token letters then alphabet fallback
local function pick_unused_key(token, used)
  if type(token) ~= "string" then
    return nil
  end

  for char in token:gmatch("%a") do
    local lower = string.lower(char)
    if not used[lower] then
      used[lower] = true
      return lower
    end
  end

  for char in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
    if not used[char] then
      used[char] = true
      return char
    end
  end

  return nil
end

-- Build submenu rows from declarative submenu specs
function M.build(capabilities, used_keys)
  local specs = type(capabilities) == "table" and capabilities.submenus or nil
  if type(specs) ~= "table" then
    return {}
  end

  local ordered_specs = {}
  for _, spec in ipairs(specs) do
    if type(spec) == "table" then
      ordered_specs[#ordered_specs + 1] = spec
    end
  end

  table.sort(ordered_specs, function(a, b)
    local a_order = get_submenu_order(a)
    local b_order = get_submenu_order(b)
    if a_order ~= b_order then
      return a_order < b_order
    end
    return tostring(a.label or a.id or "") < tostring(b.label or b.id or "")
  end)

  local rows = {}
  for _, spec in ipairs(ordered_specs) do
    local is_available = type(spec.is_available) == "function" and spec.is_available() == true or false
    local open = type(spec.open) == "function" and spec.open or nil
    if is_available and open then
      local token = tostring(spec.id or "submenu")
      local requested_key = type(spec.key) == "string" and string.lower(spec.key) or nil
      local key = requested_key
      if key and used_keys[key] then
        key = nil
      end
      if not key then
        key = pick_unused_key(token, used_keys)
      else
        used_keys[key] = true
      end

      rows[#rows + 1] = {
        key = key,
        icon = spec.icon or ">",
        label = spec.label or format_submenu_label(token),
        action = open,
      }
    end
  end

  return rows
end

return M
