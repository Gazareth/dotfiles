-- ExpressionList / binary-expression tests.
-- `local c = a + b + 1` at row 11 of lua_sample.lua gives an Assignment whose
-- value is a binary_expression chain.  In Container mode, surveying the
-- expression_list or binary_expression node should return an ExpressionList
-- container whose outline contains the flattened operands.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c)  return survey(buf, r, c) end
local function sc(r, c) return survey(buf, r, c, { mode = "container" }) end

-- ── Assignment containing a binary expression ─────────────────────────────

do -- Assignment state exposes a `value` nav target pointing at expression_list
  local r = s(11, 0)
  eq("c=a+b+1: node.node.type",   r.node.node.type,              "assignment")
  eq("c=a+b+1: state.name",       r.node.node.state.name,        "c")
  is_not_nil("c=a+b+1: state.value",    r.node.node.state.value)
  eq("c=a+b+1: value.node_type",  r.node.node.state.value.node_type, "expression_list")
end

-- ── ExpressionList node in container mode ────────────────────────────────
-- `a + b + 1` — Lua's tree-sitter parses left-associatively:
--   binary_expression(binary_expression(a, +, b), +, 1)
-- The ExpressionList container expands nested binary_expressions recursively,
-- producing a flat list of operand nodes [a, b, 1].
--
-- Row 11 layout: "local c = a + b + 1"
--   `a` starts at col 10 (after "local c = ")
--   In Container mode, surveying col 10 walks up to the binary_expression
--   which is an ExpressionList container.

do
  local r = sc(11, 10)
  is_not_nil("expr_list: r", r)
  if r then
    eq("expr_list: node_type", r.node_type, "binary_expression")
    -- After binary-expression flattening, outline has 3 operands: a, b, 1
    eq("expr_list: outline length", #r.outline, 3)
    -- All operands are leaf-like — they navigate as construct targets
    for i, item in ipairs(r.outline) do
      eq(("expr_list: outline[%d].target_mode"):format(i), item.target_mode, "construct")
    end
    -- Operands appear in source order
    eq("expr_list: outline[1].label", r.outline[1].label, "a")
    eq("expr_list: outline[2].label", r.outline[2].label, "b")
    eq("expr_list: outline[3].label", r.outline[3].label, "1")
  end
end

-- ── String concatenation (.. operator) is also a binary expression ────────
-- `"Hello, " .. name` in `greet` body at row 14.
-- In Container mode on the expression, we expect ExpressionList with 2 items.
-- Row 14: "  return \"Hello, \" .. name"
--   `"Hello, "` starts at col 9

do
  local r = sc(14, 9)
  is_not_nil("concat expr: r", r)
  if r then
    eq("concat expr: node_type", r.node_type, "binary_expression")
    eq("concat expr: outline length", #r.outline, 2)
  end
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
