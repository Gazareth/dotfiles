local common_actions = require("configs.hydra.atlantis.ops.lib.actions")
local node_common = require("configs.hydra.atlantis.anchor.probe.common.node")

local M = {}

function M.build(ctx)
  local node = type(ctx) == "table" and ctx.node_info and ctx.node_info.node or nil
  local bufnr = type(ctx) == "table" and ctx.node_info and ctx.node_info.bufnr or 0
  if not node then
    return nil
  end

  local left = node_common.get_field_node(node, "left")
    or node_common.get_field_node(node, "argument")
    or node:named_child(0)

  if not left then
    return common_actions.placeholder("Jump to", "left side")
  end

  local row, col = left:start()
  return common_actions.jump_to_target({
    bufnr = bufnr,
    row = row,
    col = col,
  })
end

return M
