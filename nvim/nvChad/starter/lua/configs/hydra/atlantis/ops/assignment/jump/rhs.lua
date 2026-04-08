local common_actions = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Assignment rhs target
local function resolve_rhs_target(ctx)
  if type(ctx) == "table" and type(ctx.target) == "table" then
    return ctx.target
  end

  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  if type(targets) == "table" and type(targets.right) == "table" then
    return targets.right
  end

  return nil
end

-- Jump to rhs target
function M.build(ctx)
  local target = resolve_rhs_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "right hand side")
  end

  return common_actions.jump_to_target(target)
end

return M
