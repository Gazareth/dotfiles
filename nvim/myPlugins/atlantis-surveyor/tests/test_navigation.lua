-- Navigation-target tests: verify the `navigation` field returned for each node.
-- NavigationTarget fields: node_type, classification, range.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end

-- ── Function ──────────────────────────────────────────────────────────────

do -- `add` function: nearest_body and nearest_function absent (it IS the function)
  local r = s(1, 0)
  -- top_level is the chunk (FileRoot) — the topmost recognised node
  is_not_nil("function: navigation.top_level",       r.navigation.top_level)
  eq("function: navigation.top_level.node_type",     r.navigation.top_level.node_type, "chunk")
  -- parent is the chunk (the next recognised ancestor)
  is_not_nil("function: navigation.parent",          r.navigation.parent)
  eq("function: navigation.parent.node_type",        r.navigation.parent.node_type, "chunk")
  -- not at top (the chunk is the top, not the function itself)
  eq("function: navigation.is_at_top",               r.navigation.is_at_top, false)
  -- no nearest_function above (function is the focus itself)
  is_nil("function: navigation.nearest_function",    r.navigation.nearest_function)
  -- no nearest_body above (function's body is a child, not an ancestor)
  is_nil("function: navigation.nearest_body",        r.navigation.nearest_body)
end

-- ── Assignment inside a function body ─────────────────────────────────────

do -- `sum = x + y` at row 3: nearest_body is the block, nearest_function is add
  local r = s(3, 2)
  is_not_nil("assignment: navigation.parent",             r.navigation.parent)
  is_not_nil("assignment: navigation.nearest_body",       r.navigation.nearest_body)
  eq("assignment: navigation.nearest_body.node_type",     r.navigation.nearest_body.node_type, "block")
  is_not_nil("assignment: navigation.nearest_function",   r.navigation.nearest_function)
  eq("assignment: navigation.nearest_function.node_type", r.navigation.nearest_function.node_type, "function_declaration")
end

-- ── Conditional ───────────────────────────────────────────────────────────

do -- `if sum > 0 then` at row 4: also inside the function body
  local r = s(4, 2)
  is_not_nil("conditional: navigation.nearest_body",     r.navigation.nearest_body)
  is_not_nil("conditional: navigation.nearest_function", r.navigation.nearest_function)
  -- sibling: the assignment on row 3 is a preceding sibling in the same body
  is_not_nil("conditional: navigation.prev_sibling",     r.navigation.prev_sibling)
  eq("conditional: prev_sibling.node_type",              r.navigation.prev_sibling.node_type, "variable_declaration")
  -- siblings cycle: if_statement is last in body, next wraps to the assignment
  is_not_nil("conditional: navigation.next_sibling",     r.navigation.next_sibling)
end

-- ── Sibling navigation ────────────────────────────────────────────────────

do -- `a = 1` at row 9: next is `b = 2`, prev wraps around to `greet`
  local r = s(9, 0)
  is_not_nil("a=1: navigation.next_sibling",  r.navigation.next_sibling)
  eq("a=1: next_sibling.node_type",           r.navigation.next_sibling.node_type, "variable_declaration")
  is_not_nil("a=1: navigation.prev_sibling",  r.navigation.prev_sibling)
end

do -- `b = 2` at row 10: prev is `a`, next is `c`
  local r = s(10, 0)
  is_not_nil("b=2: navigation.prev_sibling", r.navigation.prev_sibling)
  eq("b=2: prev_sibling.start_row",          r.navigation.prev_sibling.range.start_row, 9)
  is_not_nil("b=2: navigation.next_sibling", r.navigation.next_sibling)
  eq("b=2: next_sibling.start_row",          r.navigation.next_sibling.range.start_row, 11)
end

-- ── FileRoot ──────────────────────────────────────────────────────────────
-- FileRoot is transparent — surveying row 0 resolves to the first top-level node.
-- When at the topmost node, is_at_top is true.

do -- `add` function is the topmost construct at row 1
  local r = s(1, 0)
  -- parent is the chunk, top_level is also the chunk
  eq("add: top_level.node_type", r.navigation.top_level.node_type, "chunk")
end

-- ── ReturnStatement ───────────────────────────────────────────────────────

do -- return_statement at row 5: inside the if-body; function and body are present
  local r = s(5, 4)
  is_not_nil("return: navigation.nearest_function", r.navigation.nearest_function)
  is_not_nil("return: navigation.nearest_body",     r.navigation.nearest_body)
end
