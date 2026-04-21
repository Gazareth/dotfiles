-- Lua-specific syntax sites (standard menu, depth 0). See assert_resolution.anchor_opts.
-- Case shape: configs.hydra.atlantis.tests.menu_case

local menu_case = require("configs.hydra.atlantis.tests.menu_case")
local supported = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants").supported_nodes

describe("[Atlantis standard menu] Lua", function()
  describe("Function", function()
    -- `end` shares the surrounding function anchor (no dedicated End anchor yet).
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
    -- Chunk-level return: no anchor is attached yet.
    local chunk_return = { "return 42" }

    menu_case.run_cases({
      { "top-level return", chunk_return, 1, "return", nil, nil, { has_anchor_point = false } },
    })
  end)
end)
