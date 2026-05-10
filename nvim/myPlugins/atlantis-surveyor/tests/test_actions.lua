-- Available-actions tests: each node type returns the correct action set.
-- yank and delete are common Lua-side actions and must NOT appear here.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end
local function sc(r, c) return survey(buf, r, c, { mode = "container" }) end

-- ── Construct nodes ───────────────────────────────────────────────────────

do -- Function
  local r = s(1, 0)
  eq("function: available_actions", r.available_actions,
    { "jump_to_body", "jump_to_params", "rename" })
end

do -- Assignment
  local r = s(3, 2)
  eq("assignment: available_actions", r.available_actions,
    { "jump_lhs", "jump_rhs", "rename" })
end

do -- Conditional
  local r = s(4, 2)
  eq("conditional: available_actions", r.available_actions,
    { "jump_to_consequence", "jump_to_condition" })
end

do -- ReturnStatement — no node-specific actions
  local r = s(5, 4)
  -- available_actions is omitted from serialisation when empty
  is_nil("return: available_actions", r.available_actions)
end

-- ── Container nodes ───────────────────────────────────────────────────────

do -- FileRoot — no actions
  local r = sc(0, 0)
  is_nil("file_root: available_actions", r.available_actions)
end

do -- ParameterList — no actions
  local r = sc(1, 18)
  is_nil("param_list: available_actions", r.available_actions)
end

do -- Body — no actions
  local r = sc(4, 0)
  is_nil("body: available_actions", r.available_actions)
end

-- ── Scenario: top-level node (no parent above FileRoot) ───────────────────

do -- Function at top level still has its full action set
  local r = s(1, 0)
  eq("top-level function: actions", r.available_actions,
    { "jump_to_body", "jump_to_params", "rename" })
  eq("top-level function: is_at_top", r.navigation.is_at_top, false)
end

do -- FileRoot in container mode: is_at_top is true, no actions
  local r = sc(0, 0)
  eq("file_root: is_at_top", r.navigation.is_at_top, true)
  is_nil("file_root: available_actions", r.available_actions)
end
