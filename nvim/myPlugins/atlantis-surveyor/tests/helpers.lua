-- Shared helpers for all atlantis-surveyor integration test files.
-- Sourced once by run_all.lua before any test file is loaded.
--
-- Fixture row map for lua_sample.lua (0-indexed):
--   row 0   ""                            chunk              → FileRoot
--   row 1   "local function add(x, y)"
--           col  0  function_declaration  → Function
--           col 18  (                     → ParameterList
--   row 3   "  local sum = x + y"
--           col  2  variable_declaration  → Assignment
--   row 4   "  if sum > 0 then"
--           col  0  block                 → Body
--           col  2  if_statement          → Conditional
--   row 5   "    return sum"
--           col  4  return_statement      → ReturnStatement
--   row 9   "local a = 1"                → Assignment
--   row 10  "local b = 2"                → Assignment
--   row 11  "local c = a + b + 1"        → Assignment  (binary expr value)
--   row 13  "local function greet(name)" → Function
--   row 14  "  return ..."               → ReturnStatement

local surveyor = require("atlantis_surveyor")

-- ── Global counters (accumulate across all test files) ────────────────────

_G.passed = 0
_G.failed = 0

-- ── Assertions ────────────────────────────────────────────────────────────

function _G.eq(label, got, expected)
  if vim.deep_equal(got, expected) then
    print(("[PASS] %s"):format(label))
    _G.passed = _G.passed + 1
  else
    print(("[FAIL] %s"):format(label))
    print(("  expected: %s"):format(vim.inspect(expected)))
    print(("  got:      %s"):format(vim.inspect(got)))
    _G.failed = _G.failed + 1
  end
end

function _G.is_not_nil(label, got)
  if got ~= nil then
    print(("[PASS] %s"):format(label))
    _G.passed = _G.passed + 1
  else
    print(("[FAIL] %s  (expected non-nil, got nil)"):format(label))
    _G.failed = _G.failed + 1
  end
end

function _G.is_nil(label, got)
  if got == nil then
    print(("[PASS] %s"):format(label))
    _G.passed = _G.passed + 1
  else
    print(("[FAIL] %s  (expected nil, got %s)"):format(label, vim.inspect(got)))
    _G.failed = _G.failed + 1
  end
end

-- ── Fixture loading ───────────────────────────────────────────────────────

local test_dir = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":p:h"
)

function _G.load_fixture(name)
  local path = test_dir .. "/fixtures/" .. name
  local lines = vim.fn.readfile(path)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "lua"
  return buf
end

function _G.b(content)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  vim.bo[buf].filetype = "lua"
  return buf
end

-- ── Tree-sitter / surveyor wrappers ───────────────────────────────────────

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

-- survey(buf, row, col [, opts])
-- opts.target_hint: { type = string, row = number, col = number } to pin focus
function _G.survey(buf, row, col, opts)
  vim.api.nvim_set_current_buf(buf)
  local scan = collect_ancestry(buf, row, col)
  if opts and opts.target_hint then
    scan.target_node_type = opts.target_hint.type
    scan.target_start_row = opts.target_hint.row
    scan.target_start_col = opts.target_hint.col
  end
  return surveyor(scan, nil)
end
