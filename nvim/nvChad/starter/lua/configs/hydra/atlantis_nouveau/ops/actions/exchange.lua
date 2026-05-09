local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

return function(result)
  -- Ensure vim-exchange is loaded (it's often lazy-loaded)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { "vim-exchange" } })
  end

  -- The visual mode mapping for vim-exchange is 'X'.
  -- We use 'remap = true' to trigger the plugin's mapping.
  lib.run_on_range(result, "X", { remap = true })
end
