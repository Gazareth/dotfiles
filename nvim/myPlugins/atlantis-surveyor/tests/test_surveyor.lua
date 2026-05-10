-- atlantis-surveyor integration tests
-- Run from your Neovim session:  :source tests/test_surveyor.lua
-- Run headlessly:                tests/run.ps1  (Windows) / tests/run.sh  (Unix)
--
-- Fixture row map (0-indexed, see tests/fixtures/lua_sample.lua):
--   row 0  ""                           chunk              → FileRoot (transparent)
--   row 1  "local function add(x, y)"
--          col  0  function_declaration → Function
--          col 18  (                    → ParameterList (transparent, resolves to Function)
--   row 3  "  local sum = x + y"
--          col  2  variable_declaration → Assignment
--   row 4  "  if sum > 0 then"
--          col  0  block                → Body (transparent, resolves to Function)
--          col  2  if_statement         → Conditional
--   row 5  "    return sum"
--          col  4  return_statement     → ReturnStatement
--
-- NOTE: row 2 (blank line at top of function body) maps to function_declaration
-- in the current nvim-treesitter Lua grammar because the block node begins at
-- the first statement (row 3).

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
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, fixture_lines)
vim.bo[buf].filetype = "lua"

-- ── collect_ancestry helper (mirrors atlantis_nouveau/init.lua) ───────────────

local function node_data(bufnr, n)
  local sr, sc, er, ec = n:range()
  local data = {
    node_type = n:type(),
    start_row = sr, start_col = sc,
    end_row   = er, end_col   = ec,
    fields    = {},
    children  = {},
  }
  for child, fname in n:iter_children() do
    if child:named() then
      local csr, csc, cer, cec = child:range()
      local entry = {
        node_type = child:type(),
        start_row = csr, start_col = csc,
        end_row   = cer, end_col   = cec,
      }
      if csr == cer then
        local ok_t, t = pcall(vim.treesitter.get_node_text, child, bufnr)
        if ok_t then entry.text = t end
      end
      if fname then
        data.fields[fname] = entry
      else
        table.insert(data.children, entry)
      end
    end
  end
  return data
end

local function collect_ancestry(bufnr, row, col)
  local ft = vim.bo[bufnr].filetype
  local parser = vim.treesitter.get_parser(bufnr, ft)
  parser:parse()
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
  local ancestry = {}
  local cur = node
  while cur do
    table.insert(ancestry, node_data(bufnr, cur))
    cur = cur:parent()
  end
  return { filetype = ft, ancestry = ancestry }
end

local function survey(row, col)
  local scan = collect_ancestry(buf, row, col)
  return surveyor(scan, nil)
end

-- ── Semantic nodes ────────────────────────────────────────────────────────────

print("\n── Semantic nodes ──")

do -- Function  (row 1, col 0 → function_declaration)
  local r = survey(1, 0)
  eq("function: node_type",         r.node_type,                    "function_declaration")
  eq("function: node.node.type",    r.node.node.type,               "function")
  eq("function: state.name",        r.node.node.state.name,         "add")
  eq("function: state.is_async",    r.node.node.state.is_async,     false)
  eq("function: available_actions", r.available_actions,            { "rename" })
end

do -- Assignment  (row 3, col 2 → variable_declaration)
  local r = survey(3, 2)
  eq("assignment: node_type",               r.node_type,                           "variable_declaration")
  eq("assignment: node.type",               r.node.node.type,                      "assignment")
  eq("assignment: state.name",              r.node.node.state.name,                "sum")
  eq("assignment: state.is_local_binding",  r.node.node.state.is_local_binding,    true)
  eq("assignment: available_actions",       r.available_actions,                   { "rename" })
end

do -- Conditional  (row 4, col 2 → if_statement)
  local r = survey(4, 2)
  eq("conditional: node_type",         r.node_type,         "if_statement")
  eq("conditional: node.type",         r.node.node.type,    "conditional")
  eq("conditional: available_actions", r.available_actions, nil)
end

do -- ReturnStatement  (row 5, col 4)
  local r = survey(5, 4)
  eq("return: node_type",    r.node_type,       "return_statement")
  eq("return: node.type",    r.node.node.type,  "return_statement")
end

-- ── Transparent structural nodes ──────────────────────────────────────────────

print("\n── Transparent nodes ──")

do -- FileRoot/chunk (row 0): transparent, resolves to first top-level semantic node
  local r = survey(0, 0)
  -- chunk is transparent; result is a recognised semantic node, not chunk itself
  eq("file_root: no actions", r.available_actions, nil)
end

do -- ParameterList (row 1, col 18 → `(` of `add(x, y)`): resolves to Function
  local r = survey(1, 18)
  eq("param_list resolves to function: node.node.type", r.node.node.type, "function")
end

do -- Body/block (row 4, col 0): resolves to enclosing Function
  local r = survey(4, 0)
  eq("body resolves to function: node.node.type", r.node.node.type, "function")
end

-- ── Summary ───────────────────────────────────────────────────────────────────

print(("\n%d passed, %d failed"):format(passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
end
