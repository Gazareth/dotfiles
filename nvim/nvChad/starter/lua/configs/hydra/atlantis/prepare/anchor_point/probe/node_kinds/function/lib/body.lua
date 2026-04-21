local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")

local M = {}

local BLOCK_TYPES = {
  block = true,
  statement_block = true,
  compound_statement = true,
}

--- @return userdata|nil body TSNode
function M.find_body_block(function_node)
  if not function_node then
    return nil
  end
  local ok, body = pcall(function()
    return function_node:child_by_field_name("body")
  end)
  if ok and body then
    return body
  end
  for _, child in ipairs(node_common.list_named_children(function_node)) do
    if BLOCK_TYPES[child:type()] then
      return child
    end
  end
  return nil
end

--- @return integer named_child_count, userdata|nil body_node
function M.body_named_child_count(function_node)
  local body = M.find_body_block(function_node)
  if not body then
    return 0, nil
  end
  return body:named_child_count(), body
end

return M
