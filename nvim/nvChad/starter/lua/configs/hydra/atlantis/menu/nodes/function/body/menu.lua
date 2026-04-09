local M = {}

-- Submenu for function body (nested functions and assignments)
function M.build(node_info, parsed)
  if not parsed or not parsed.targets then
    return {
      title = "Body",
      items = {
        {
          separator = true,
          label = "No body items found",
        },
      },
    }
  end

  local targets = parsed.targets
  local items = {}

  local nested_count = #(targets.nested_functions or {})
  local assignment_count = #(targets.assignments or {})

  items[#items + 1] = {
    separator = true,
    label = "󰅲 Nested Functions: " .. tostring(nested_count),
  }

  for index, fn_target in ipairs(targets.nested_functions or {}) do
    items[#items + 1] = {
      key = tostring(index),
      icon = ".",
      label = fn_target.name or ("nested function " .. tostring(index)),
    }
  end

  items[#items + 1] = {
    separator = true,
    label = "󰌭 Assignments: " .. tostring(assignment_count),
  }

  for index, assign_target in ipairs(targets.assignments or {}) do
    items[#items + 1] = {
      key = string.char(96 + index), -- a, b, c, ...
      icon = ".",
      label = assign_target.name or ("assignment " .. tostring(index)),
    }
  end

  return {
    title = "Body",
    items = items,
  }
end

return M
