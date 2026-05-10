-- Navigation-target tests: assert the `navigation` field returned for each
-- node type. NavigationTarget fields: node_type, classification, range, target_mode.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end
local function sc(r, c) return survey(buf, r, c, { mode = "container" }) end

-- ── Function ──────────────────────────────────────────────────────────────

do -- `add` function: nearest_body and nearest_function are absent (it IS the function)
  local r = s(1, 0)
  -- top_level is the chunk (FileRoot) since that's the topmost recognised node
  is_not_nil("function: navigation.top_level",       r.navigation.top_level)
  eq("function: navigation.top_level.node_type",     r.navigation.top_level.node_type, "chunk")
  -- parent is the chunk container
  is_not_nil("function: navigation.parent",          r.navigation.parent)
  eq("function: navigation.parent.node_type",        r.navigation.parent.node_type, "chunk")
  -- not at top (the chunk is the top, not the function itself)
  eq("function: navigation.is_at_top",               r.navigation.is_at_top, false)
  -- no nearest_function above (function is the focus itself)
  is_nil("function: navigation.nearest_function",    r.navigation.nearest_function)
  -- no nearest_body above (function's body is below it, not an ancestor)
  is_nil("function: navigation.nearest_body",        r.navigation.nearest_body)
end

-- ── Assignment inside a function body ─────────────────────────────────────

do -- `sum = x + y` at row 3: parent is the function, nearest_body is the block
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
  -- siblings cycle: if_statement is last in body, so next wraps to the assignment
  is_not_nil("conditional: navigation.next_sibling",     r.navigation.next_sibling)
end

-- ── Sibling navigation ────────────────────────────────────────────────────

do -- `a = 1` at row 9: prev sibling wraps around to `greet` (last item), next is `b = 2`
  local r = s(9, 0)
  is_not_nil("a=1: navigation.next_sibling",  r.navigation.next_sibling)
  eq("a=1: next_sibling.node_type",           r.navigation.next_sibling.node_type, "variable_declaration")
  -- prev wraps around to the last top-level item (siblings cycle)
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

do -- FileRoot at row 0 in container mode: is_at_top, no parent, no siblings
  local r = sc(0, 0)
  eq("file_root: navigation.is_at_top",   r.navigation.is_at_top, true)
  is_nil("file_root: navigation.parent",  r.navigation.parent)
  is_nil("file_root: navigation.prev_sibling", r.navigation.prev_sibling)
  is_nil("file_root: navigation.next_sibling", r.navigation.next_sibling)
end

-- ── ReturnStatement ───────────────────────────────────────────────────────

do -- return_statement at row 5: inside the if-body; function and body present
  local r = s(5, 4)
  is_not_nil("return: navigation.nearest_function", r.navigation.nearest_function)
  is_not_nil("return: navigation.nearest_body",     r.navigation.nearest_body)
end
