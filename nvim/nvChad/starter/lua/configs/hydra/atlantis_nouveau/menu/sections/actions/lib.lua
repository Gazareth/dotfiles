local M = {}

function M.item(key, icon, label, fn)
  return { key = key, icon = icon, label = label, action = fn }
end

-- Lifts a registry entry into a menu item, binding result at call time.
function M.from_reg(entry, result)
  return M.item(entry.key, entry.icon, entry.label, function() entry.fn(result) end)
end

return M
