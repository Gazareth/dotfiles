-- Build function jump-to-body action that reopens Atlantis at body depth
local atlantis = require("configs.hydra.hydras.atlantis")
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

local function resolve_body_target(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil

  local nested = type(targets) == "table" and targets.nested_functions or nil
  if type(nested) == "table" and type(nested[1]) == "table" then
    return nested[1]
  end

  local assignments = type(targets) == "table" and targets.assignments or nil
  if type(assignments) == "table" and type(assignments[1]) == "table" then
    return assignments[1]
  end

  return nil
end

local function jump_and_open_at_depth(target, depth)
  return function()
    common_actions.jump_to_target(target)()

    atlantis.open({ depth = depth })
  end
end

function M.build(ctx)
  local target = resolve_body_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "body")
  end

  return jump_and_open_at_depth(target, 1)
end

return M
