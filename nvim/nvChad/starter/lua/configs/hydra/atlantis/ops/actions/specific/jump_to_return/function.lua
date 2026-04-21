-- First return_statement under this function's body (skips nested function-like subtrees).
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")
local function_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.constants")
local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")

local M = {}

local function body_root(fn_node)
  if not fn_node then
    return nil
  end
  return node_common.get_field_node(fn_node, "body") or fn_node
end

local function find_return_skip_nested(node)
  if not node then
    return nil
  end
  if node:type() == "return_statement" then
    return node
  end
  local n = node:named_child_count()
  for i = 0, n - 1 do
    local child = node:named_child(i)
    local ct = child:type()
    if function_constants.function_like_types[ct] then
      -- Do not search inside nested functions.
    else
      local r = find_return_skip_nested(child)
      if r then
        return r
      end
    end
  end
  return nil
end

function M.build(ctx)
  local node_info = type(ctx) == "table" and ctx.node_info or nil
  local fn_node = node_info and node_info.node or nil
  if not fn_node then
    return nil
  end

  local root = body_root(fn_node)
  local ret = find_return_skip_nested(root)
  if not ret then
    return nil
  end

  local row, col = ret:start()
  return common_actions.jump_to_target({
    bufnr = node_info.bufnr,
    row = row,
    col = col,
  })
end

return M
