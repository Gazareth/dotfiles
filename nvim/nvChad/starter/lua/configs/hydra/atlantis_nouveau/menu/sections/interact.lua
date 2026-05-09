local registry = require("configs.hydra.atlantis_nouveau.ops.registry")

local M = {}

function M.build(result)
  local items = {}
  local filter = { yank = true, delete = true, change = true }
  for _, action_key in ipairs(result.available_actions or {}) do
    if not filter[action_key] then
      local entry = registry[action_key]
      if entry then
        items[#items + 1] = {
          key    = entry.key,
          icon   = entry.icon,
          label  = entry.label,
          action = function() entry.fn(result) end,
        }
      end
    end
  end
  return { title = "Actions", items = items }
end

return M
