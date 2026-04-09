local M = {}

-- Read node text safely with empty-string fallback
function M.get_node_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok then
    return ""
  end

  return text or ""
end

-- Check whether node is nested inside ancestor node
function M.is_descendant_of(node, ancestor)
  local current = node
  while current do
    if current:id() == ancestor:id() then
      return true
    end

    current = current:parent()
  end

  return false
end

-- Find nearest ancestor matching type set and optional predicate
function M.find_ancestor_of_types(node, type_set, opts)
  local include_self = type(opts) == "table" and opts.include_self == true
  local predicate = type(opts) == "table" and opts.predicate or nil

  local current = include_self and node or (node and node:parent() or nil)
  while current do
    if type_set[current:type()] == true then
      if type(predicate) ~= "function" or predicate(current) == true then
        return current
      end
    end

    current = current:parent()
  end

  return nil
end

-- Build jump target payload from node position and labels
function M.build_target(node, bufnr, label, role, name)
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

-- Resolve target display name from node text or fallback
function M.get_target_name(node, bufnr, fallback)
  local text = vim.trim(M.get_node_text(node, bufnr))
  if text == "" then
    return fallback
  end

  return text
end

-- Read child field node safely by field name
function M.get_field_node(node, field_name)
  local ok, child = pcall(node.child_by_field_name, node, field_name)
  if not ok then
    return nil
  end

  return child
end

-- Collect named children in source order
function M.list_named_children(node)
  local children = {}
  local child_count = node:named_child_count()

  for index = 0, child_count - 1 do
    children[#children + 1] = node:named_child(index)
  end

  return children
end

return M
