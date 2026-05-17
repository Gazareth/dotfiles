local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

local M = {}

function M.run(result)
  local ok, refactoring = pcall(require, "refactoring")
  if not ok then return end
  lib.run_on_range(result, "", { mode = "V" })
  refactoring.select_refactor()
end

return M
