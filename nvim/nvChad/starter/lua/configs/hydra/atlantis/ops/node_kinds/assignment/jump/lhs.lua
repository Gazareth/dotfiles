local common_actions = require("configs.hydra.atlantis.ops.node_kinds.common")

local M = {}

-- Assignment lhs target
local function resolve_lhs_target(ctx)
  if type(ctx) == "table" and type(ctx.target) == "table" then
    return ctx.target
  end

  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  if type(targets) == "table" and type(targets.left) == "table" then
    return targets.left
  end

  return nil
end

-- Jump to lhs target
function M.build(ctx)
  local target = resolve_lhs_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "left hand side")
  end

  return common_actions.jump_to_target(target)
end

return M
