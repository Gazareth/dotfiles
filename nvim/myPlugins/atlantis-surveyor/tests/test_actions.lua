-- Available-actions tests: each node type returns the correct action set.
-- yank and delete are common Lua-side actions and must NOT appear here.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end

-- ── Semantic nodes ────────────────────────────────────────────────────────

do -- Function: only rename remains now that jump actions are gone
  local r = s(1, 0)
  eq("function: available_actions", r.available_actions, { "rename" })
end

do -- Assignment: only rename
  local r = s(3, 2)
  eq("assignment: available_actions", r.available_actions, { "rename" })
end

do -- Conditional: no actions
  local r = s(4, 2)
  is_nil("conditional: available_actions", r.available_actions)
end

do -- ReturnStatement: no actions
  local r = s(5, 4)
  is_nil("return: available_actions", r.available_actions)
end

-- ── Structural groupings (transparent during traversal) ───────────────────
-- The surveyor anchors on the nearest recognised semantic node when the
-- cursor lands on a transparent grouping, so these resolve outward.

do -- Cursor on ParameterList → resolves to the enclosing Function
  local r = s(1, 18)
  eq("param_list resolves to function: available_actions", r.available_actions, { "rename" })
end

do -- Cursor on block (Body) → resolves to the enclosing Function
  local r = s(4, 0)
  eq("body resolves to function: available_actions", r.available_actions, { "rename" })
end

-- ── Top-level node ────────────────────────────────────────────────────────

do -- Function at top level: is_at_top is false (FileRoot is above it)
  local r = s(1, 0)
  eq("top-level function: is_at_top", r.navigation.is_at_top, false)
  eq("top-level function: actions", r.available_actions, { "rename" })
end
