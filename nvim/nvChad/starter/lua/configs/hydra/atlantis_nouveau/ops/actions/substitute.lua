local lib = require("configs.hydra.atlantis_nouveau.ops.actions.lib")

return function(result)
  -- Ensure substitute is loaded (it's often lazy-loaded)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { "substitute.nvim" } })
  end

  -- The visual mode mapping for substitute.nvim is 'S' in your configuration.
  -- We use 'remap = true' to trigger the plugin's mapping.
  lib.run_on_range(result, "S", { remap = true })
end
