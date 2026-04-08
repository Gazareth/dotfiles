local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Node text fallback
local function get_node_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok then
    return ""
  end

  return text or ""
end

-- Field lookup fallback
local function get_field_node(node, field_name)
  local ok, child = pcall(node.child_by_field_name, node, field_name)
  if not ok then
    return nil
  end

  return child
end

-- Named child list
local function list_named_children(node)
  local children = {}
  local child_count = node:named_child_count()

  for index = 0, child_count - 1 do
    children[#children + 1] = node:named_child(index)
  end

  return children
end

-- Assignment side nodes
local function resolve_assignment_nodes(node)
  local left = get_field_node(node, "left")
    or get_field_node(node, "name")
    or get_field_node(node, "variable")
    or get_field_node(node, "key")
  local right = get_field_node(node, "right")
    or get_field_node(node, "value")

  if left or right then
    return left, right
  end

  local children = list_named_children(node)
  if #children >= 2 then
    return children[1], children[#children]
  end

  return children[1], nil
end

-- Jump target shape
local function build_target(node, bufnr, label, role, name)
  if not node then
    return nil
  end

  local row, col = node:start()

  return {
    bufnr = bufnr,
    row = row,
    col = col,
    label = label,
    role = role,
    name = name,
  }
end

-- Assignment side label
local function get_target_name(node, bufnr, fallback)
  local text = vim.trim(get_node_text(node, bufnr))
  if text == "" then
    return fallback
  end

  return text
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
      left = build_target(
        left_node,
        node_info.bufnr,
        "left hand side",
        "Left",
        get_target_name(left_node, node_info.bufnr, "left hand side")
      ),
      right = build_target(
        right_node,
        node_info.bufnr,
        "right hand side",
        "Right",
        get_target_name(right_node, node_info.bufnr, "right hand side")
      ),
    },
  }
end

return M