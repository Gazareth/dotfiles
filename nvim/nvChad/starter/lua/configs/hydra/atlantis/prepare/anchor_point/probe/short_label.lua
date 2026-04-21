-- Prefer a short display string from a TS node's structure (name fields, inner expression, LHS).
-- Used before falling back to full node span text; jump/menu label policy stays in menu_labels.
local M = {}

local function safe_get_text(node, bufnr)
  if not node then
    return nil
  end
  local ok, tx = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok or type(tx) ~= "string" then
    return nil
  end
  tx = vim.trim(tx)
  if tx == "" then
    return nil
  end
  return tx
end

local function safe_field_first_text(node, bufnr, field)
  if not node then
    return nil
  end
  local ok, parts = pcall(function()
    return node:field(field)
  end)
  if not ok or type(parts) ~= "table" or not parts[1] then
    return nil
  end
  return safe_get_text(parts[1], bufnr)
end

local function walk(node, bufnr, depth)
  if not node or depth > 12 then
    return nil
  end

  local t = node:type()

  local from_name = safe_field_first_text(node, bufnr, "name")
  if from_name then
    return from_name
  end

  if t == "expression_statement" then
    local c = node:named_child(0)
    if c then
      return walk(c, bufnr, depth + 1)
    end
    return nil
  end

  if t == "variable_declaration" or t == "lexical_declaration" or t == "local_declaration" then
    local c = node:named_child(0)
    if c then
      return walk(c, bufnr, depth + 1)
    end
  end

  if t == "assignment_statement" or t == "assignment_expression" then
    local left = safe_field_first_text(node, bufnr, "left")
    if left then
      return left
    end
    local c = node:named_child(0)
    if c then
      return walk(c, bufnr, depth + 1)
    end
  end

  if t == "variable_declarator" then
    local id = safe_field_first_text(node, bufnr, "name") or safe_field_first_text(node, bufnr, "id")
    if id then
      return id
    end
  end

  if t == "variable_list" or t == "expression_list" then
    local c = node:named_child(0)
    if c then
      return walk(c, bufnr, depth + 1)
    end
  end

  return nil
end

--- When the node span is large (e.g. whole function), return a shorter source string; else nil.
function M.preferred_text(node_info)
  local node = node_info and node_info.node
  local bufnr = node_info and node_info.bufnr
  if not node or bufnr == nil then
    return nil
  end
  return walk(node, bufnr, 0)
end

return M
