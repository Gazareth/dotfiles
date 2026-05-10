-- Edge cases and regression tests for specific navigation/classification bugs.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end

-- ── Same-kind skip ────────────────────────────────────────────────────────
-- `variable_declaration` wraps `assignment_statement` in modern Lua grammar.
-- Navigation should skip the redundant wrapper when computing the parent.
do
  local r = s(3, 2)
  eq("same-kind skip: node.node.type is assignment", r.node.node.type, "assignment")
  eq("same-kind skip: node_type",                   r.node_type,       "variable_declaration")
  eq("same-kind skip: state.name",                  r.node.node.state.name, "sum")
end

-- ── Unrecognised token climb ───────────────────────────────────────────────
-- The `return` keyword itself is unrecognised but its parent is
-- `return_statement`, which is recognised — the resolver climbs to it.
do
  local r = s(5, 4)
  eq("return climb: node_type",      r.node_type,      "return_statement")
  eq("return climb: node.node.type", r.node.node.type, "return_statement")
end

-- ── Cursor on sub-expression: Leaf resolution ────────────────────────────
-- On row 11 `local c = a + b + 1`, landing on `a` (col 10) stays on the
-- identifier Leaf instead of climbing to Assignment, because the parent
-- is a transparent ExpressionList.
do
  local r = s(11, 10)
  is_not_nil("sub-expr r", r)
  if r then
    eq("sub-expr climb: node.kind", r.node and r.node.kind, "leaf")
    eq("sub-expr climb: node_type", r.node_type,            "identifier")
  end
end

-- ── Same-range dedup ──────────────────────────────────────────────────────
-- Modern Lua `local x = 1`:
--   variable_declaration [0,0 - 0,11]
--   assignment_statement [0,0 - 0,11]  ← same range
-- The parent navigation should skip the same-range wrapper and jump to chunk.
do
  local r = s(9, 0)
  is_not_nil("same-range dedup: parent exists", r.navigation.parent)
  if r.navigation.parent then
    eq("same-range dedup: parent is chunk", r.navigation.parent.node_type, "chunk")
  end
end

-- ── Transparent node resolves to semantic parent ──────────────────────────
-- Surveying inside a ParameterList or Body climbs to the enclosing function.
do -- col 18 is the `(` of `add(x, y)` — ParameterList is transparent
  local r = s(1, 18)
  eq("param_list transparent: resolves to function", r.node.node.type, "function")
end

do -- col 0 row 4 is the `block` node before the `if` keyword — Body is transparent
  local r = s(4, 0)
  eq("body transparent: resolves to function", r.node.node.type, "function")
end
