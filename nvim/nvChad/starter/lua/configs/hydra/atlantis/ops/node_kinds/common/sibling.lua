local M = {}

-- Resolve adapter label text for user-facing messages
local function adapter_label(adapter)
  if type(adapter) == "table" and type(adapter.label) == "function" then
    local value = adapter:label()
    if type(value) == "string" and value ~= "" then
      return value
    end
  end

  return "Node"
end

-- Notify when a directional sibling target is unavailable
local function notify_unavailable(adapter, direction)
  vim.notify("<" .. adapter_label(adapter) .. "> has no available " .. direction .. " sibling", vim.log.levels.INFO)
end

-- Notify when no sibling target is available
local function notify_no_sibling(adapter)
  vim.notify("<" .. adapter_label(adapter) .. "> has no available sibling", vim.log.levels.INFO)
end

-- Build jump action that targets previous or next sibling
local function build_jump_action(adapter, direction)
  return function()
    local target = type(adapter) == "table" and type(adapter.target) == "function" and adapter:target(direction) or nil
    if type(target) ~= "table" then
      notify_unavailable(adapter, direction)
      return
    end

    if type(adapter) == "table" and type(adapter.jump) == "function" then
      adapter:jump(target)
    end
  end
end

-- Build swap action that exchanges with previous or next sibling
local function build_swap_action(adapter, direction)
  return function()
    local target = type(adapter) == "table" and type(adapter.target) == "function" and adapter:target(direction) or nil
    if type(target) ~= "table" then
      notify_unavailable(adapter, direction)
      return
    end

    local current_index = type(adapter) == "table" and type(adapter.current_index) == "function" and adapter:current_index() or nil
    if type(current_index) ~= "number" then
      notify_unavailable(adapter, direction)
      return
    end

    local offset = direction == "previous" and -1 or 1
    local swapped = type(adapter) == "table" and type(adapter.swap_to_index) == "function"
      and adapter:swap_to_index(current_index + offset)
      or false
    if swapped ~= true then
      notify_unavailable(adapter, direction)
    end
  end
end

-- Build picker jump action for selecting any sibling target
local function build_jump_prompt_action(adapter)
  return function()
    local targets = type(adapter) == "table" and type(adapter.target_list) == "function" and adapter:target_list() or {}
    if type(targets) ~= "table" or #targets == 0 then
      notify_no_sibling(adapter)
      return
    end

    local labels = type(adapter) == "table" and type(adapter.target_labels) == "function" and adapter:target_labels(targets) or {}

    vim.ui.select(labels, {
      prompt = "Jump to sibling",
      format_item = function(item)
        return item
      end,
    }, function(_, selected_index)
      if type(selected_index) ~= "number" then
        return
      end

      local target = targets[selected_index]
      if type(adapter) == "table" and type(adapter.jump) == "function" then
        adapter:jump(target)
      end
    end)
  end
end

-- Build picker swap action for selecting sibling swap target
local function build_swap_prompt_action(adapter)
  return function()
    local targets = type(adapter) == "table" and type(adapter.target_list) == "function" and adapter:target_list() or {}
    local current_index = type(adapter) == "table" and type(adapter.current_index) == "function" and adapter:current_index() or nil
    if type(targets) ~= "table" or #targets <= 1 or type(current_index) ~= "number" then
      notify_no_sibling(adapter)
      return
    end

    local choices = {}
    for index, target in ipairs(targets) do
      if index ~= current_index then
        choices[#choices + 1] = {
          index = index,
          text = tostring(index) .. ": " .. tostring(target.name or (adapter_label(adapter):lower() .. " " .. tostring(index))),
        }
      end
    end

    if #choices == 0 then
      notify_no_sibling(adapter)
      return
    end

    vim.ui.select(choices, {
      prompt = "Swap with sibling",
      format_item = function(item)
        return item.text
      end,
    }, function(choice)
      if type(choice) ~= "table" or type(choice.index) ~= "number" then
        return
      end

      if type(adapter) == "table" and type(adapter.swap_to_index) == "function" then
        adapter:swap_to_index(choice.index)
      end
    end)
  end
end

-- Attach sibling helper API onto adapter instance
function M.attach(adapter)
  if type(adapter) ~= "table" then
    return adapter
  end

  local sibling = {}

  -- Report previous sibling availability
  function sibling:has_previous()
      return type(adapter.target) == "function" and adapter:target("previous") ~= nil
  end

  -- Report next sibling availability
  function sibling:has_next()
      return type(adapter.target) == "function" and adapter:target("next") ~= nil
  end

  -- Report whether any sibling exists
  function sibling:has_any()
      local targets = type(adapter.target_list) == "function" and adapter:target_list() or {}
      return type(targets) == "table" and #targets > 0
  end

  -- Report whether at least one swap candidate exists
  function sibling:has_swappable()
      local targets = type(adapter.target_list) == "function" and adapter:target_list() or {}
      return type(targets) == "table" and #targets > 1
  end

  -- Jump callback for previous sibling
  sibling.jump_previous = build_jump_action(adapter, "previous")

  -- Jump callback for next sibling
  sibling.jump_next = build_jump_action(adapter, "next")

  -- Swap callback for previous sibling
  sibling.swap_previous = build_swap_action(adapter, "previous")

  -- Swap callback for next sibling
  sibling.swap_next = build_swap_action(adapter, "next")

  -- Jump callback for picked sibling
  sibling.jump_prompt = build_jump_prompt_action(adapter)

  -- Swap callback for picked sibling
  sibling.swap_prompt = build_swap_prompt_action(adapter)

  adapter.sibling = sibling

  return adapter
end

return M