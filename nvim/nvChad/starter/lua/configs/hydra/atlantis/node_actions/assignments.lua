local common_actions = require("configs.hydra.atlantis.node_actions.common")

local M = {}

-- LHS target from assignment context
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

function M.jump_to_lhs(ctx)
  local lhs_target = resolve_lhs_target(ctx)
  if not lhs_target then
    return common_actions.placeholder("Jump to", "left hand side")
  end

  return common_actions.jump_to_target(lhs_target)
end

-- RHS target from assignment context
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

-- Jump to right hand side from context
function M.jump_to_rhs(ctx)
  local rhs_target = resolve_rhs_target(ctx)
  if not rhs_target then
    return common_actions.placeholder("Jump to", "right hand side")
  end

  return common_actions.jump_to_target(rhs_target)
end

return M
