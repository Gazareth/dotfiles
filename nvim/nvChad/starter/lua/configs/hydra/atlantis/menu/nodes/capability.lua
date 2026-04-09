local title_builder = require("configs.hydra.atlantis.menu.title")
local action_rows = require("configs.hydra.atlantis.menu.actions.rows")
local action_registry = require("configs.hydra.atlantis.menu.actions.registry")
local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Build stable action name order with generic-first priority
local function build_action_order(node_kind)
  local enabled = node_actions.action_names_by_node_kind[node_kind]
  if type(enabled) ~= "table" then
    return {}
  end

  local ordered = {}
  local seen = {}

  for _, action_name in ipairs(action_registry.generic_action_order or {}) do
    if enabled[action_name] == true then
      ordered[#ordered + 1] = action_name
      seen[action_name] = true
    end
  end

  local extras = {}
  for action_name, is_enabled in pairs(enabled) do
    if is_enabled == true and not seen[action_name] then
      extras[#extras + 1] = action_name
      seen[action_name] = true
    end
  end

  table.sort(extras)
  for _, action_name in ipairs(extras) do
    ordered[#ordered + 1] = action_name
  end

  return ordered
end

-- Format submenu token into user-facing label text
local function format_submenu_label(token)
  local spaced = tostring(token or "submenu"):gsub("_", " ")
  local title = spaced:gsub("(%a)([%w_']*)", function(a, b)
    return string.upper(a) .. string.lower(b)
  end)

  return title .. "..."
end

-- Resolve submenu sort order with max fallback
local function get_submenu_order(spec)
  local order = type(spec) == "table" and spec.order or nil
  if type(order) == "number" then
    return order
  end

  return math.huge
end

-- Pick first unused key from token letters then alphabet fallback
local function build_submenu_key(token, used)
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

-- Build submenu rows from declarative capability submenu specs
local function build_submenu_rows_from_specs(specs, used_keys)
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

    local a_label = tostring(a.label or a.id or "")
    local b_label = tostring(b.label or b.id or "")
    return a_label < b_label
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
        key = build_submenu_key(token, used_keys)
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

-- Build submenu rows from legacy lookup token callbacks
local function build_submenu_rows_from_lookup(lookup, used_keys)
  if type(lookup) ~= "table" then
    return {}
  end

  local tokens = {}
  for key, value in pairs(lookup) do
    local token = type(key) == "string" and key:match("^has_(.+)_submenu$") or nil
    if token and type(value) == "function" then
      local open_fn = lookup["open_" .. token .. "_submenu"]
      if type(open_fn) == "function" and value() == true then
        tokens[#tokens + 1] = token
      end
    end
  end

  table.sort(tokens)

  local rows = {}
  for _, token in ipairs(tokens) do
    local key = build_submenu_key(token, used_keys)
    rows[#rows + 1] = {
      key = key,
      icon = ">",
      label = format_submenu_label(token),
      action = lookup["open_" .. token .. "_submenu"],
    }
  end

  return rows
end

-- Build submenu rows using specs first then legacy lookup fallback
local function build_submenu_rows(capabilities, used_keys)
  local specs = type(capabilities) == "table" and capabilities.submenus or nil
  local rows = build_submenu_rows_from_specs(specs, used_keys)
  if #rows > 0 then
    return rows
  end

  local lookup = type(capabilities) == "table" and capabilities.lookup or nil
  return build_submenu_rows_from_lookup(lookup, used_keys)
end

-- Collect already-used row keys to avoid submenu key collisions
local function collect_used_keys(rows)
  local used = {}
  for _, row in ipairs(rows or {}) do
    if type(row) == "table" and type(row.key) == "string" and row.key ~= "" then
      used[string.lower(row.key)] = true
    end
  end

  return used
end

-- Build capability-driven menu spec for parsed node
function M.build(node_info, parsed, runtime_ctx)
  local node_kind = type(parsed) == "table" and parsed.node_kind or nil
  local capabilities = type(runtime_ctx) == "table" and runtime_ctx.capabilities or nil
  local action_order = build_action_order(node_kind)

  local rows = action_rows.build_rows(node_kind, action_order, {
    ctx = {
      node_info = node_info,
      parsed = parsed,
    },
    capabilities = capabilities,
  })

  local used_keys = collect_used_keys(rows)
  local submenu_rows = build_submenu_rows(capabilities, used_keys)

  local items = {
    {
      heading = "Actions",
    },
    {
      separator = true,
    },
  }

  for _, row in ipairs(rows) do
    items[#items + 1] = row
  end

  if #submenu_rows > 0 then
    items[#items + 1] = {
      separator = true,
    }

    for _, row in ipairs(submenu_rows) do
      items[#items + 1] = row
    end
  end

  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    items = items,
  }
end

return M