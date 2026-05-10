-- Classification tests: each recognised node type resolves to the correct
-- node.node.type and state fields.
-- Requires helpers.lua to have been sourced.

local buf = load_fixture("lua_sample.lua")
local function s(r, c) return survey(buf, r, c) end
local function sc(r, c) return survey(buf, r, c, { mode = "container" }) end

-- ── Construct nodes ───────────────────────────────────────────────────────

do -- Function  (row 1, col 0 → function_declaration)
  local r = s(1, 0)
  eq("function: node_type",           r.node_type,                  "function_declaration")
  eq("function: node.node.type",      r.node.node.type,             "function")
  eq("function: state.name",          r.node.node.state.name,       "add")
  eq("function: state.is_async",      r.node.node.state.is_async,   false)
  is_not_nil("function: state.parameters",    r.node.node.state.parameters)
  is_not_nil("function: state.body",          r.node.node.state.body)
  -- parameters nav target points at the parameters node
  eq("function: state.parameters.node_type",  r.node.node.state.parameters.node_type, "parameters")
  -- body nav target points at the block node
  eq("function: state.body.node_type",        r.node.node.state.body.node_type,       "block")
end

do -- Assignment  (row 3, col 2 → variable_declaration)
  local r = s(3, 2)
  eq("assignment: node_type",              r.node_type,                         "variable_declaration")
  eq("assignment: node.node.type",         r.node.node.type,                    "assignment")
  eq("assignment: state.name",             r.node.node.state.name,              "sum")
  eq("assignment: state.is_local_binding", r.node.node.state.is_local_binding,  true)
  is_not_nil("assignment: state.lhs",      r.node.node.state.lhs)
  is_not_nil("assignment: state.value",    r.node.node.state.value)
end

do -- Conditional  (row 4, col 2 → if_statement)
  local r = s(4, 2)
  eq("conditional: node_type",    r.node_type,       "if_statement")
  eq("conditional: node.node.type", r.node.node.type, "conditional")
  is_not_nil("conditional: state.condition",   r.node.node.state.condition)
  is_not_nil("conditional: state.consequence", r.node.node.state.consequence)
end

do -- ReturnStatement  (row 5, col 4 → return_statement)
  local r = s(5, 4)
  eq("return: node_type",        r.node_type,       "return_statement")
  eq("return: node.node.type",   r.node.node.type,  "return_statement")
end

do -- Function: second function with a single parameter  (row 13, col 0)
  local r = s(13, 0)
  eq("greet: node_type",      r.node_type,              "function_declaration")
  eq("greet: node.node.type", r.node.node.type,         "function")
  eq("greet: state.name",     r.node.node.state.name,   "greet")
  is_not_nil("greet: state.parameters", r.node.node.state.parameters)
  is_not_nil("greet: state.body",       r.node.node.state.body)
end

do -- Assignment: top-level, no local binding  (row 9, col 0 → "local a = 1")
  -- local declarations ARE local bindings; this checks the extended fixture
  local r = s(9, 0)
  eq("a=1: node.node.type",         r.node.node.type,                   "assignment")
  eq("a=1: state.name",             r.node.node.state.name,             "a")
  eq("a=1: state.is_local_binding", r.node.node.state.is_local_binding, true)
end

-- ── Container nodes ───────────────────────────────────────────────────────
-- Containers must be requested explicitly via mode="container".

do -- FileRoot  (row 0, col 0 → chunk)
  local r = sc(0, 0)
  eq("file_root: node_type",      r.node_type,       "chunk")
  eq("file_root: node.node.type", r.node.node.type,  "file_root")
end

do -- ParameterList  (row 1, col 18 → `(` of `add(x, y)`)
  local r = sc(1, 18)
  eq("param_list: node_type",      r.node_type,       "parameters")
  eq("param_list: node.node.type", r.node.node.type,  "parameter_list")
end

do -- Body  (row 4, col 0 → block, before the `if` keyword at col 2)
  local r = sc(4, 0)
  eq("body: node_type",      r.node_type,       "block")
  eq("body: node.node.type", r.node.node.type,  "body")
end
