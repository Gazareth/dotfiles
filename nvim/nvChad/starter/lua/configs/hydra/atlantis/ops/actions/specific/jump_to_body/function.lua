-- Build function jump-to-body action that reopens Atlantis at body depth
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

-- Resolve first function body target from parsed payload
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

-- Build closure that jumps then reopens menu at the requested depth
local function jump_and_open_at_depth(target, depth)
  return function()
    common_actions.jump_to_target(target)()

    local Menu = require("configs.hydra.common.menu")
    local atlantis_layout = require("configs.hydra.atlantis.menu.layout")
    Menu.open(atlantis_layout.build_menu_spec({ depth = depth }))
  end
end

-- Build jump-to-body closure with fallback placeholder
function M.build(ctx)
  local target = resolve_body_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "body")
  end

  return jump_and_open_at_depth(target, 1)
end

return M
