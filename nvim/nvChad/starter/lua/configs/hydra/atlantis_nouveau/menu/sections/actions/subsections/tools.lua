local lib    = require("configs.hydra.atlantis_nouveau.menu.sections.actions.lib")
local tools  = require("configs.hydra.atlantis_nouveau.ops.actions").tools

local item = lib.item

local M = {}

function M.build(result, ctx)
  local items       = {}
  local refactor_ok = pcall(require, "refactoring")

  if ctx.lsp_attached then
    items[#items + 1] = item("A", "", "LSP Actions", function() tools.lsp.run(result) end)
  end
  if refactor_ok then
    items[#items + 1] = item("R", "", "Refactor", function() tools.refactoring.run(result) end)
  end

  return items
end

return M
