local common_actions = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

function M.build(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  local nxt = type(targets) == "table" and targets.next_parameter or nil
  if not nxt then
    return nil
  end
  return common_actions.jump_to_target(nxt)
end

return M
