local M = {}

-- Return an action that jumps the cursor to a target location.
function M.jump_to_target(target)
  return function()
    if type(target) ~= "table" then
      return
    end

    if type(target.bufnr) == "number" and vim.api.nvim_buf_is_valid(target.bufnr) then
      vim.api.nvim_set_current_buf(target.bufnr)
    end

    local row = (target.row or 0) + 1
    local col = target.col or 0

    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
    pcall(vim.cmd, "normal! zz")
  end
end

-- Build the sequence of available one-key shortcuts.
function M.build_hotkey_pool()
  local pool = {}
  for char in ("1234567890abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
    pool[#pool + 1] = char
  end
  return pool
end

-- Pick the next unused one-key hotkey from a pool.
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

-- Append parameter navigation rows to the menu.
function M.append_parameter_rows(items, targets, hotkeys, used, cursor)
  local parameters = targets.parameters or {}
  local parameter_container = targets.parameter_container

  if parameter_container then
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = "Go to parameters",
      action = M.jump_to_target(parameter_container),
    }
  end

  for index, target in ipairs(parameters) do
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = "Go to parameter " .. tostring(index),
      action = M.jump_to_target(target),
    }
  end

  return cursor
end

-- Append nested-function navigation rows to the menu.
function M.append_nested_function_rows(items, targets, hotkeys, used, cursor)
  for _, target in ipairs(targets.nested_functions or {}) do
    local label = target.label or "nested function"
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = "Go to " .. label,
      action = M.jump_to_target(target),
    }
  end

  return cursor
end

-- Append assignment navigation rows with a capped preview.
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
      label = "Go to assignment " .. tostring(index),
      action = M.jump_to_target(target),
    }
  end

  if #assignments > max_preview then
    local key
    key, cursor = M.next_hotkey(hotkeys, used, cursor)
    items[#items + 1] = {
      key = key,
      icon = ">",
      label = "Go to assignment n",
      action = function() end,
    }
  end

  return cursor
end

return M
