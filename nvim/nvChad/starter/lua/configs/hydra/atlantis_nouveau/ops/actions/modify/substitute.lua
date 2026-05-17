local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

return function(result)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { "substitute.nvim" } })
  end
  lib.run_on_range(result, "S", { remap = true })
end
