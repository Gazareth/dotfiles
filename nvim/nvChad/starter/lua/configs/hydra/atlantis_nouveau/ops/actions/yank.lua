local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

return function(result)
  lib.run_on_range(result, "y")
  vim.notify("[atlantis] yanked", vim.log.levels.INFO)
end
