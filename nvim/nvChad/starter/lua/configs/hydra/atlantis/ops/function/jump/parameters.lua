local common_actions = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Parameters target
local function resolve_parameters_target(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  if type(targets) == "table" and type(targets.parameter_container) == "table" then
    return targets.parameter_container
  end

  return nil
end

-- Jump to parameters
function M.build(ctx)
  local target = resolve_parameters_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "parameters")
  end

  return common_actions.jump_to_target(target)
end

return M
