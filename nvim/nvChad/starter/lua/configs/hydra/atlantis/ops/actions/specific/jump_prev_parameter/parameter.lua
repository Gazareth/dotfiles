local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

function M.build(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  local prev = type(targets) == "table" and targets.previous_parameter or nil
  if not prev then
    return nil
  end
  return common_actions.jump_to_target(prev)
end

return M
