local M = {}

-- Submenu for function parameters
function M.build(node_info, parsed)
  if not parsed or not parsed.targets then
    return {
      title = "Parameters",
      items = {
        {
          separator = true,
          label = "No parameters found",
        },
      },
    }
  end

  local targets = parsed.targets
  local items = {}
  
  items[#items + 1] = {
    separator = true,
    label = "󰆧 Parameters: " .. tostring(#(targets.parameters or {})),
  }

  for index, param_target in ipairs(targets.parameters or {}) do
    items[#items + 1] = {
      key = tostring(index),
      icon = ".",
      label = param_target.name or ("parameter " .. tostring(index)),
    }
  end

  return {
    title = "Parameters",
    items = items,
  }
end

return M
