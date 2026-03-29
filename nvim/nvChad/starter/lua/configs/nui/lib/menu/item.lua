local str = require("configs.nui.lib.string")

local M = {}

-- Execute a menu item by preferring direct action callbacks, then resolver fallback.
function M.run(menu, choice)
  if type(choice.action) == "function" then
    choice.action(choice)
    return
  end

  if type(menu.resolve) == "function" then
    menu.resolve(choice)
  end
end

-- Safely ensure menu shortcut keys are lowercase.
function M.normalize_key(key)
  local normalized = str.non_empty_or(key, nil)
  if normalized == nil then
    return nil
  end

  return normalized:lower()
end

return M
