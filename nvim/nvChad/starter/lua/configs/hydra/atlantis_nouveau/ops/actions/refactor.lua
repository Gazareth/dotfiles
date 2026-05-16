local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

local M = {}

function M.run(result)
  local ok, refactoring = pcall(require, "refactoring")
  if not ok then return end
  -- Select the node in visual mode then invoke select_refactor from that context
  lib.run_on_range(result, "", { mode = "V" })
  refactoring.select_refactor()
end

return M
