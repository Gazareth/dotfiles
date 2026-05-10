local s = _G.survey
local b = _G.b
local eq = _G.eq
local is_not_nil = _G.is_not_nil

do -- nil focus in complex expressions
  local content = [[local probe_id = semantic_kind and kinds.probe_by_node_kind[semantic_kind] or nil]]
  local buf = b(content)
  
  -- Position of `nil` at the end of the line
  local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  local col = line:find("nil") - 1
  
  local r = s(buf, 0, col)
  
  is_not_nil("nil_focus: r is not nil", r)
  if r then
    eq("nil_focus: node_type", r.node_type, "nil")
    -- Correct structure check: r.node is the AtlantisNode, it has a 'kind' field.
    eq("nil_focus: node.kind", r.node and r.node.kind, "leaf")
  end
end
