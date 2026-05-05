local supported_nodes = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.constants").supported_nodes
local node_common = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.common.node")

local M = {}

-- Binary expression parse result
function M.parse_binary_expression(node_info)
  local node = node_info.node
  local bufnr = node_info.bufnr
  local left = node_common.get_field_node(node, "left") or (node:named_child_count() >= 1 and node:named_child(0) or nil)
  local right = node_common.get_field_node(node, "right") or (node:named_child_count() >= 2 and node:named_child(1) or nil)

  return {
    node_kind = supported_nodes.binary_expression,
    role = "binary expression",
    display_name = "binary expression",
    summary = {
      parent_type = node_info.parent_type,
      text = node_info.text,
    },
    targets = {
      left = left and node_common.build_target(
        left,
        bufnr,
        "left hand side",
        "Left",
        node_common.get_target_name(left, bufnr, "left hand side")
      ) or nil,
      right = right and node_common.build_target(
        right,
        bufnr,
        "right hand side",
        "Right",
        node_common.get_target_name(right, bufnr, "right hand side")
      ) or nil,
    },
  }
end

return M
