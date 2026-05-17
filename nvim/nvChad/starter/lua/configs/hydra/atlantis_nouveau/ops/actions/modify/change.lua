local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

return function(result)
  lib.run_on_range(result, "c", { enter_insert = true })
end
