-- Build assignment jump-rhs from parsed right target
local lib = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Resolve assignment right-hand target from parsed payload
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

-- Build assignment jump-rhs closure
function M.build(ctx)
  local target = resolve_rhs_target(ctx)
  if not target then
    return lib.placeholder("Jump to", "right hand side")
  end

  return lib.jump_to_target(target)
end

return M
