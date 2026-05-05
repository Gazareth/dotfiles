local supported_nodes = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.constants").supported_nodes
local node_common = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.common.node")

local M = {}

-- Assignment side nodes
local function resolve_assignment_nodes(node)
  local left = node_common.get_field_node(node, "left")
    or node_common.get_field_node(node, "name")
    or node_common.get_field_node(node, "variable")
    or node_common.get_field_node(node, "key")
  local right = node_common.get_field_node(node, "right")
    or node_common.get_field_node(node, "value")

  if left or right then
    return left, right
  end

  local children = node_common.list_named_children(node)
  if #children >= 2 then
    return children[1], children[#children]
  end

  return children[1], nil
end

-- Assignment parse result
function M.parse_assignment(node_info)
  local left_node, right_node = resolve_assignment_nodes(node_info.node)
  local line_span = (node_info.end_row - node_info.start_row) + 1

  return {
    node_kind = supported_nodes.assignment,
    role = "assignment",
    display_name = "assignment",
    metrics = {
      line_span = line_span,
      is_local = node_info.text:match("^%s*local%s") ~= nil,
    },
    targets = {
      left = node_common.build_target(
        left_node,
        node_info.bufnr,
        "left hand side",
        "Left",
        node_common.get_target_name(left_node, node_info.bufnr, "left hand side")
      ),
      right = node_common.build_target(
        right_node,
        node_info.bufnr,
        "right hand side",
        "Right",
        node_common.get_target_name(right_node, node_info.bufnr, "right hand side")
      ),
    },
  }
end

return M