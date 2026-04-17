-- Lua-specific syntax sites (standard menu, depth 0). See assert_resolution.anchor_opts.
-- Case shape: configs.hydra.atlantis.tests.menu_case

local menu_case = require("configs.hydra.atlantis.tests.menu_case")
local supported = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

describe("[Atlantis standard menu] Lua", function()
  describe("Function", function()
    -- TDD: `end` token may get its own anchor; today the surrounding function wins.
    local fn_three = {
      "local function foo()",
      "  return 1",
      "end",
    }

    menu_case.run_cases({
      { "End", fn_three, 3, "end", supported.fn, "Function" },
    })
  end)

  describe("Boolean expression", function()
    local if_then = {
      "if x then",
      "  return",
      "end",
    }

    menu_case.run_cases({
      { "then", if_then, 1, "then", supported.generic },
    })
  end)

  describe("Module return statement", function()
    -- TDD: `return` at chunk top should be Return; build does not attach an anchor yet.
    local chunk_return = { "return 42" }

    menu_case.run_cases({
      { "top-level return (unresolved today)", chunk_return, 1, "return", nil, nil, { has_anchor_point = false } },
    })
  end)
end)
