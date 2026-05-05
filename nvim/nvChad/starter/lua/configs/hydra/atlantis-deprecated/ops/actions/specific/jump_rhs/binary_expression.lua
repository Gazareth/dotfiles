local common_actions = require("configs.hydra.atlantis-deprecated.ops.lib.actions")
local node_common = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.common.node")

local M = {}

function M.build(ctx)
  local node = type(ctx) == "table" and ctx.node_info and ctx.node_info.node or nil
  local bufnr = type(ctx) == "table" and ctx.node_info and ctx.node_info.bufnr or 0
  if not node then
    return nil
  end

  local right = node_common.get_field_node(node, "right")
  if not right then
    local n = node:named_child_count()
    right = n >= 2 and node:named_child(n - 1) or nil
  end

  if not right then
    return common_actions.placeholder("Jump to", "right side")
  end

  local row, col = right:start()
  return common_actions.jump_to_target({
    bufnr = bufnr,
    row = row,
    col = col,
  })
end

return M
