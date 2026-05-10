-- Outline tests: assert the `outline` field for container-mode nodes.
-- OutlineItem fields: label (first non-blank line, max 16 chars), node_type, range, target_mode.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function sc(r, c) return survey(buf, r, c, { mode = "container" }) end

-- ── Body of `add` function (2 children: assignment + conditional) ─────────

do
  local r = sc(4, 0)  -- block node, before the `if` keyword
  eq("body: outline length", #r.outline, 2)
  -- first child: variable_declaration on row 3
  is_not_nil("body: outline[1]",                    r.outline[1])
  eq("body: outline[1].node_type",                  r.outline[1].node_type, "variable_declaration")
  eq("body: outline[1].range.start_row",            r.outline[1].range.start_row, 3)
  -- label is the trimmed first line of the node's text, max 16 chars
  -- "local sum = x + y" (17 chars) → "local sum = x + "
  eq("body: outline[1].label",                      r.outline[1].label, "local sum = x + ")
  -- constructs navigate as construct targets
  eq("body: outline[1].target_mode",                r.outline[1].target_mode, "construct")
  -- second child: if_statement on row 4
  is_not_nil("body: outline[2]",                    r.outline[2])
  eq("body: outline[2].node_type",                  r.outline[2].node_type, "if_statement")
  eq("body: outline[2].range.start_row",            r.outline[2].range.start_row, 4)
  eq("body: outline[2].label",                      r.outline[2].label, "if sum > 0 then")
  eq("body: outline[2].target_mode",                r.outline[2].target_mode, "construct")
end

-- ── ParameterList of `add(x, y)` (2 parameters) ──────────────────────────

do
  local r = sc(1, 18)  -- `(` of `add(x, y)`
  eq("param_list: outline length", #r.outline, 2)
  is_not_nil("param_list: outline[1]", r.outline[1])
  is_not_nil("param_list: outline[2]", r.outline[2])
  eq("param_list: outline[1].label", r.outline[1].label, "x")
  eq("param_list: outline[2].label", r.outline[2].label, "y")
  eq("param_list: outline[1].target_mode", r.outline[1].target_mode, "construct")
end

-- ── FileRoot with multiple top-level nodes ────────────────────────────────

do
  local r = sc(0, 0)
  -- Extended fixture has: add (row 1), a (row 9), b (row 10), c (row 11), greet (row 13)
  eq("file_root: outline length", #r.outline, 5)
  eq("file_root: outline[1].range.start_row", r.outline[1].range.start_row, 1)
  eq("file_root: outline[2].range.start_row", r.outline[2].range.start_row, 9)
  eq("file_root: outline[3].range.start_row", r.outline[3].range.start_row, 10)
  eq("file_root: outline[4].range.start_row", r.outline[4].range.start_row, 11)
  eq("file_root: outline[5].range.start_row", r.outline[5].range.start_row, 13)
  -- function_declaration is a construct target
  eq("file_root: outline[1].target_mode", r.outline[1].target_mode, "construct")
end

-- ── Body of `greet` function (1 child: the return statement) ─────────────
-- Auto-drill fires when a container has exactly one outline item.
-- The container_skip logic resolves through it to the child construct.

do
  -- Position inside greet's body block (col 4 = `r` of `return`, past the block's col-2 start).
  -- Container mode finds the block, which has one child → auto-drill fires.
  local r = sc(14, 4)
  -- The block drills into the return statement (Construct).
  eq("greet body drill: node_type", r.node_type, "return_statement")
end

-- ── Empty outline: ReturnStatement has no outline ─────────────────────────
-- (ReturnStatement is a Construct; Constructs produce empty outlines.)

do
  local r = survey(buf, 14, 4)  -- return_statement, Construct mode (default)
  eq("return: outline is empty", #(r.outline or {}), 0)
end
