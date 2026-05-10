-- Top-level test runner.
-- Run headlessly:  tests/run.ps1  (Windows) / tests/run.sh  (Unix)
-- Run in Neovim:   :luafile tests/run_all.lua

local test_dir = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":p:h"
)

local function run(name)
  print(("\n══ %s ══"):format(name))
  dofile(test_dir .. "/" .. name)
end

dofile(test_dir .. "/helpers.lua")

run("test_classification.lua")
run("test_actions.lua")
run("test_navigation.lua")
run("test_outline.lua")
run("test_edge_cases.lua")
run("test_expressions.lua")
run("test_nil_focus.lua")

print(("\n%d passed, %d failed"):format(_G.passed, _G.failed))

if _G.failed > 0 then
  vim.cmd("cquit 1")
end
