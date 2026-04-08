local M = {}
local action_ids = require("configs.hydra.atlantis.treesitter.lib.atlantis.constants").action_ids
local common_actions = require("configs.hydra.atlantis.node_actions.common")

-- Jump label role-name format
local function format_jump_label(target, fallback_role, fallback_name)
  local role = fallback_role
  local name = fallback_name

  if type(target) == "table" then
    if type(target.role) == "string" and target.role ~= "" then
      role = target.role
    end
    if type(target.name) == "string" and target.name ~= "" then
      name = target.name
    end
  end

  role = vim.trim(tostring(role or "Target"))
  name = vim.trim(tostring(name or "item"))
  return "[" .. role .. "] " .. name
end

-- Cursor jump to a target node
function M.jump_to_target(target)
  return common_actions.jump_to_target(target)
end

-- One-key shortcut pool
function M.build_hotkey_pool()
  local pool = {}
  for char in ("1234567890abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
    pool[#pool + 1] = char
  end
  return pool
end

-- Next unused shortcut key
function M.next_hotkey(pool, used, cursor)
  local index = cursor
  while index <= #pool do
    local candidate = pool[index]
    if not used[candidate] then
      used[candidate] = true
      return candidate, index + 1
    end
    index = index + 1
  end

  return nil, index
end

-- Jump rows for parameters
function M.append_parameter_rows(items, targets, hotkeys, used, cursor)
  local parameters = targets.parameters or {}
  local parameter_container = targets.parameter_container

  if parameter_container then
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = format_jump_label(parameter_container, "Parameters", "list"),
      action_id = action_ids.jump,
      action = M.jump_to_target(parameter_container),
    }
  end

  for index, target in ipairs(parameters) do
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = format_jump_label(target, "Parameter", tostring(index)),
      action_id = action_ids.jump,
      action = M.jump_to_target(target),
    }
  end

  return cursor
end

-- Jump rows for nested functions
function M.append_nested_function_rows(items, targets, hotkeys, used, cursor)
  for _, target in ipairs(targets.nested_functions or {}) do
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = format_jump_label(target, "Function", "nested function"),
      action_id = action_ids.jump,
      action = M.jump_to_target(target),
    }
  end

  return cursor
end

-- Jump rows for assignments
function M.append_assignment_rows(items, targets, hotkeys, used, cursor)
  local assignments = targets.assignments or {}
  local max_preview = math.min(3, #assignments)

  for index = 1, max_preview do
    local target = assignments[index]
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = format_jump_label(target, "Assignment", tostring(index)),
      action_id = action_ids.jump,
      action = M.jump_to_target(target),
    }
  end

  if #assignments > max_preview then
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = format_jump_label(nil, "Assignment", "n"),
      action_id = action_ids.jump,
      action = function() end,
    }
  end

  return cursor
end

return M
