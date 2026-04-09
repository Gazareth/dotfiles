local common_actions = require("configs.hydra.atlantis.ops.node_kinds.common")

local M = {}

-- Function body target
local function resolve_body_target(ctx)
  if type(ctx) == "table" and type(ctx.target) == "table" then
    return ctx.target
  end

  return common_actions.resolve_target(ctx)
end

-- Jump to body
function M.build(ctx)
  local target = resolve_body_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "body")
  end

  return common_actions.jump_to_target(target)
end

return M
