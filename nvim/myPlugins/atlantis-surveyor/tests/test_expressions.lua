-- ExpressionList / binary-expression tests.
-- `local c = a + b + 1` at row 11 of lua_sample.lua gives an Assignment whose
-- value is a binary_expression chain. Surveying the assignment exposes the
-- value NavigationTarget; surveying an operand directly yields a Leaf with
-- siblings navigable across the flattened expression.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end

-- ── Assignment containing a binary expression ─────────────────────────────

do -- Assignment state exposes a `value` nav target pointing at expression_list
  local r = s(11, 0)
  eq("c=a+b+1: node.node.type",   r.node.node.type,              "assignment")
  eq("c=a+b+1: state.name",       r.node.node.state.name,        "c")
  is_not_nil("c=a+b+1: state.value",    r.node.node.state.value)
  eq("c=a+b+1: value.node_type",  r.node.node.state.value.node_type, "expression_list")
end

-- ── Sibling navigation inside an ExpressionList ───────────────────────────
-- Within a flattened expression list, siblings cycle through the operands.

do
  -- Survey `a` directly using a target hint to bypass the Assignment climb
  local r = survey(buf, 11, 10, {
    target_hint = { type = "identifier", row = 11, col = 10 }
  })
  -- If the cursor resolves to `a` and has siblings in the expression list:
  is_not_nil("expr sibling: next_sibling", r.navigation.next_sibling)
  -- The next sibling should be `b` (or similar operand node)
  eq("expr sibling: next_sibling start_row", r.navigation.next_sibling.range.start_row, 11)
end

-- ── String concatenation (.. operator) is also a binary expression ────────
-- `"Hello, " .. name` in `greet` body at row 14.
-- Row 14: "  return \"Hello, \" .. name"
-- Surveying at col 9 (`"Hello, "`) resolves to the Leaf identifier;
-- siblings should exist (the other operand).

do
  local r = survey(buf, 14, 9, {
    target_hint = { type = "string", row = 14, col = 9 }
  })
  is_not_nil("concat expr: result", r)
  -- Sibling navigation: the other operand `name` should be navigable
  is_not_nil("concat expr: next_sibling", r.navigation.next_sibling)
end
