local common_actions = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

local function resolve_parameter_target(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  local params = type(targets) == "table" and targets.parameters or nil

  if type(params) == "table" and type(params[1]) == "table" then
    return params[1]
  end

  local container = type(targets) == "table" and targets.parameter_container or nil
  if type(container) == "table" then
    return container
  end

  return nil
end

function M.build(ctx)
  local target = resolve_parameter_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "parameter")
  end
  return common_actions.jump_to_target(target)
end

return M
