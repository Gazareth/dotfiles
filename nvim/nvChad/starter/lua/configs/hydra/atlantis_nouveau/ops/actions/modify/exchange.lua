local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

return function(result)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { "vim-exchange" } })
  end
  lib.run_on_range(result, "X", { remap = true })
end
