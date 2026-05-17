local lib    = require("configs.hydra.atlantis_nouveau.menu.sections.actions.lib")
local defs   = require("configs.hydra.atlantis_nouveau.menu.sections.actions.defs")
local create = require("configs.hydra.atlantis_nouveau.ops.actions.create")

local item = lib.item

local M = {}

function M.build(result, ctx)
  local items = {}

  for _, group in ipairs(defs) do
    if ctx.avail[group.token] then
      for _, def in ipairs(group.items) do
        if not def.when or def.when(result) then
          items[#items + 1] = item(def.key, def.icon, def.label, function() def.fn(result) end)
        end
      end
      break
    end
  end

  if ctx.lsp_attached then
    items[#items + 1] = item("N", "", "New import", function() create.import.run(result) end)
  end

  return items
end

return M
