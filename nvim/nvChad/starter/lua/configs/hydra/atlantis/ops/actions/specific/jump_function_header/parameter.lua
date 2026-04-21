local common_actions = require("configs.hydra.atlantis.ops.lib.actions")
local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")
local function_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.constants")
local fn_targets = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.targets")

local M = {}

function M.build(ctx)
  local node_info = type(ctx) == "table" and ctx.node_info or nil
  local node = node_info and node_info.node or nil
  if not node then
    return nil
  end

  local fn_node = node_common.find_ancestor_of_types(node, function_constants.function_like_types, {
    include_self = true,
  })
  if not fn_node then
    return nil
  end

  local synthetic = {
    node = fn_node,
    bufnr = node_info.bufnr,
  }
  local target = fn_targets.build_function_name_target(synthetic)
  if not target then
    local row, col = fn_node:start()
    target = { bufnr = node_info.bufnr, row = row, col = col }
  end
  return common_actions.jump_to_target(target)
end

return M
