-- atlantis-surveyor integration tests
-- Run from your Neovim session:  :source tests/test_surveyor.lua
-- Run headlessly:                tests/run.ps1  (Windows) / tests/run.sh  (Unix)
--
-- Fixture row map (0-indexed, see tests/fixtures/lua_sample.lua):
--   row 0  ""                           chunk              → Container  FileRoot
--   row 1  "local function add(x, y)"
--          col  0  function_declaration → Construct        Function
--          col 18  (                    → Container        ParameterList
--   row 3  "  local sum = x + y"
--          col  2  variable_declaration → Construct        Assignment
--   row 4  "  if sum > 0 then"
--          col  0  block                → Container        Body
--          col  2  if_statement         → Construct        Conditional
--   row 5  "    return sum"
--          col  4  return_statement     → Unrecognised
--
-- NOTE: Construct::Call (function_call) is unreachable via cursor position in
-- Lua because tree-sitter's named children cover every byte of a call
-- expression, leaving no position where function_call itself is innermost.
--
-- NOTE: row 2 (blank line at top of function body) maps to function_declaration
-- in the current nvim-treesitter Lua grammar because the block node begins at
-- the first statement (row 3). The Body container is therefore tested at
-- row 4 col 0 where the block node is innermost (before the if keyword).

local surveyor = require("atlantis_surveyor")

-- ── Paths ─────────────────────────────────────────────────────────────────────

local test_dir = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":p:h"
)
local fixture_path = test_dir .. "/fixtures/lua_sample.lua"

-- ── Test runner ───────────────────────────────────────────────────────────────

local passed, failed = 0, 0

local function eq(label, got, expected)
  if vim.deep_equal(got, expected) then
    print(("[PASS] %s"):format(label))
    passed = passed + 1
  else
    print(("[FAIL] %s"):format(label))
    print(("  expected: %s"):format(vim.inspect(expected)))
    print(("  got:      %s"):format(vim.inspect(got)))
    failed = failed + 1
  end
end

-- ── Fixture buffer ────────────────────────────────────────────────────────────

local fixture_lines = vim.fn.readfile(fixture_path)
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, fixture_lines)
vim.bo[buf].filetype = "lua"

local function survey(row, col)
  return surveyor.node(buf, row, col)
end

-- ── Constructs ────────────────────────────────────────────────────────────────

print("\n── Constructs ──")

do -- Function  (row 1, col 0 → function_declaration)
  local r = survey(1, 0)
  eq("function: node_type",         r.node_type,                    "function_declaration")
  eq("function: variant.kind",      r.variant.kind,                 "construct")
  eq("function: variant.lang",      r.variant.lang,                 "lua")
  eq("function: node.type",         r.variant.node.type,            "function")
  eq("function: state.name",        r.variant.node.state.name,      "add")
  eq("function: state.is_async",    r.variant.node.state.is_async,  false)
  eq("function: available_actions", r.available_actions,
    { "jump_to_body", "jump_to_params", "rename", "yank", "delete" })
end

do -- Assignment  (row 3, col 2 → variable_declaration)
  local r = survey(3, 2)
  eq("assignment: node_type",               r.node_type,                             "variable_declaration")
  eq("assignment: variant.kind",            r.variant.kind,                          "construct")
  eq("assignment: node.type",               r.variant.node.type,                     "assignment")
  eq("assignment: state.name",              r.variant.node.state.name,               "sum")
  eq("assignment: state.is_local_binding",  r.variant.node.state.is_local_binding,   true)
  eq("assignment: available_actions",       r.available_actions,
    { "jump_lhs", "jump_rhs", "rename", "yank" })
end

do -- Conditional  (row 4, col 2 → if_statement)
  local r = survey(4, 2)
  eq("conditional: node_type",         r.node_type,         "if_statement")
  eq("conditional: variant.kind",      r.variant.kind,      "construct")
  eq("conditional: node.type",         r.variant.node.type, "conditional")
  eq("conditional: available_actions", r.available_actions,
    { "jump_to_body", "jump_to_condition", "yank" })
end

-- ── Containers ────────────────────────────────────────────────────────────────

print("\n── Containers ──")

do -- FileRoot  (row 0 → chunk; blank line before any code)
  local r = survey(0, 0)
  eq("file_root: node_type",    r.node_type,         "chunk")
  eq("file_root: variant.kind", r.variant.kind,      "container")
  eq("file_root: node.type",    r.variant.node.type, "file_root")
  eq("file_root: no actions",   r.available_actions, nil)
end

do -- ParameterList  (row 1, col 18 → `(` of `add(x, y)`)
  local r = survey(1, 18)
  eq("param_list: node_type",    r.node_type,         "parameters")
  eq("param_list: variant.kind", r.variant.kind,      "container")
  eq("param_list: node.type",    r.variant.node.type, "parameter_list")
  eq("param_list: no actions",   r.available_actions, nil)
end

do -- Body  (row 4, col 0 → block node is innermost before the `if` keyword)
  local r = survey(4, 0)
  eq("body: node_type",    r.node_type,         "block")
  eq("body: variant.kind", r.variant.kind,      "container")
  eq("body: node.type",    r.variant.node.type, "body")
  eq("body: no actions",   r.available_actions, nil)
end

-- ── Unrecognised ──────────────────────────────────────────────────────────────

print("\n── Unrecognised ──")

do -- return statement  (row 5, col 4)
  local r = survey(5, 4)
  eq("unrecognised: variant.kind", r.variant.kind,      "unrecognised")
  eq("unrecognised: no actions",   r.available_actions, nil)
end

-- ── Summary ───────────────────────────────────────────────────────────────────

print(("\n%d passed, %d failed"):format(passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
end
