-- Edge cases and regression tests for specific navigation/classification bugs.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end
local function sc(r, c) return survey(buf, r, c, { mode = "container" }) end

-- ── Same-kind skip ────────────────────────────────────────────────────────
-- `variable_declaration` wraps `assignment_statement` in modern Lua.
-- Navigation should skip the redundant wrapper and focus on the assignment.
do
  local r = s(3, 2)
  eq("same-kind skip: node.node.type is assignment", r.node.node.type, "assignment")
  eq("same-kind skip: node_type",                   r.node_type,       "variable_declaration")
  eq("same-kind skip: state.name",                  r.node.node.state.name, "sum")
end

-- ── Return climb ──────────────────────────────────────────────────────────
-- The `return` keyword is unrecognised, so it should climb to its parent
-- Construct (`return_statement`).
do
  local r = s(5, 4)
  -- Since return_statement is now in the Lua map, the walk stops here:
  eq("return climb: node_type",      r.node_type,      "return_statement")
  eq("return climb: node.node.type", r.node.node.type, "return_statement")
end

-- ── Cursor on sub-expression focuses the leaf ─────────────────────────────
-- On row 11 `local c = a + b + 1`, landing on `a` (col 10) in Construct mode
-- now stays on the identifier Leaf instead of climbing to Assignment.
do
  local r = s(11, 10)
  is_not_nil("sub-expr r", r)
  if r then
    eq("sub-expr climb: node.kind",      r.node and r.node.kind,  "leaf")
    eq("sub-expr climb: node_type",       r.node_type,       "identifier")
  end
end

-- ── Auto-drill: single-statement FileRoot ─────────────────────────────────
-- single_statement.lua has exactly one top-level node (the `only` function).
-- In Container mode on the chunk (FileRoot), the sole-child drill fires and
-- resolves to the function construct.

do
  local buf_single = load_fixture("single_statement.lua")
  local r = survey(buf_single, 0, 0, { mode = "container" })
  eq("auto-drill FileRoot: node_type",      r.node_type,       "function_declaration")
  eq("auto-drill FileRoot: node.node.type", r.node.node.type,  "function")
  eq("auto-drill FileRoot: state.name",     r.node.node.state.name, "only")
end

-- ── Auto-drill: single-statement Body ─────────────────────────────────────
-- In greet's body block, the sole return statement is drilled into.

do
  local r = sc(14, 4)
  -- The block drills into the return statement (Construct).
  eq("auto-drill body: node_type", r.node_type, "return_statement")
end

-- ── No-drill: multiple children ───────────────────────────────────────────
-- If a container has multiple children, no auto-drill should occur.

do
  local r = sc(4, 0) -- add() body has 2 statements
  eq("no-drill multi-child: node_type",      r.node_type,       "block")
  eq("no-drill multi-child: node.node.type", r.node.node.type,  "body")
  eq("no-drill multi-child: outline length", #r.outline, 2)
end

-- ── Same-range dedup ──────────────────────────────────────────────────────
-- Modern Lua `local x = 1`
--   variable_declaration [0,0 - 0,11]
--   assignment_statement [0,0 - 0,11]
-- Ancestry should skip the redundant top-level assignment_statement if its
-- range exactly matches the parent variable_declaration.
do
  local r = s(9, 0)
  is_not_nil("same-range dedup: parent exists", r.navigation.parent)
  if r.navigation.parent then
    -- It should have skipped assignment_statement and found chunk (FileRoot)
    eq("same-range dedup: parent is not variable_declaration", r.navigation.parent.node_type, "chunk")
  end
end
