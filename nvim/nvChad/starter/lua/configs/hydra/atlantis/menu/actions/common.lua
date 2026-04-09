local action_registry = require("configs.hydra.atlantis.menu.actions.registry")
local action_rows = require("configs.hydra.atlantis.menu.actions.rows")

local M = {}

-- Generic action rows from registry
function M.build_generic_action_rows(anchor_type, label, opts)
  -- Generic row options payload
  local row_ctx = type(opts) == "table" and (opts.ctx or opts) or nil
  local capabilities = type(opts) == "table" and opts.capabilities or nil

  return action_rows.build_rows(anchor_type, action_registry.generic_action_order, {
    label = label,
    ctx = row_ctx,
    capabilities = capabilities,
  })
end

return M