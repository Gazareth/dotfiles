-- Build identifier rename from cursor target
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Trigger LSP rename at current cursor
local function run_rename()
  local ok, err = pcall(vim.lsp.buf.rename)
  if ok then
    return
  end

  vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
end

-- Build identifier rename closure
function M.build(ctx)
  local target = lib.resolve_target(ctx)
  if not target then
    return lib.placeholder("Rename", lib.resolve_node_label(ctx))
  end

  return function()
    run_rename()
  end
end

return M
