local lib = require("configs.hydra.atlantis.ops.common.lib")

local M = {}

-- Navigate action behavior
function M.build(ctx)
  local target = lib.resolve_target(ctx)
  if not target then
    return lib.placeholder("Navigate to", lib.resolve_node_label(ctx))
  end

  return lib.jump_to_target(target)
end

return M
