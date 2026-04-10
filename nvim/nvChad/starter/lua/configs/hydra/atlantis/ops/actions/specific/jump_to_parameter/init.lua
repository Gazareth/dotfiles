-- Build function jump-to-parameter action that reopens Atlantis at parameter depth
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

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

local function jump_and_open_at_depth(target, depth)
  return function()
    common_actions.jump_to_target(target)()

    local Menu = require("configs.hydra.common.menu")
    local atlantis_layout = require("configs.hydra.atlantis.menu.layout")
    Menu.open(atlantis_layout.build_menu_spec({ depth = depth }))
  end
end

function M.build(ctx)
  local target = resolve_parameter_target(ctx)
  if not target then
    return common_actions.placeholder("Jump to", "parameter")
  end

  return jump_and_open_at_depth(target, 1)
end

return M
