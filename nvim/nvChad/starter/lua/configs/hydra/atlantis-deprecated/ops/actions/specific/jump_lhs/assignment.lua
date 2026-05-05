-- Build assignment jump-lhs from parsed left target
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Resolve assignment left-hand target from parsed payload
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

-- Build assignment jump-lhs closure
function M.build(ctx)
  local target = resolve_lhs_target(ctx)
  if not target then
    return lib.placeholder("Jump to", "left hand side")
  end

  return lib.jump_to_target(target)
end

return M
