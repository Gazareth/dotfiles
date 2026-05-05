-- Standard hint menu at anchor depth 1 (nested context). See assert_resolution.anchor_opts + extras.depth.
-- Same tuple shape as core_spec; extras include depth = 1 and optional positioned_at.

local menu_case = require("configs.hydra.atlantis-deprecated.tests.menu_case")
local supported = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.constants").supported_nodes

--- Merge extras with `depth = 1` for assertions + menu_opts.
local function extras1(t)
  return vim.tbl_extend("force", { depth = 1 }, t or {})
end

describe("[Standard mode] depth: 1", function()
  describe("Function parameters", function()
    local fn_two_params = {
      "local function foo(a, b)",
      "  return a + b",
      "end",
    }
    local fn_empty_params = {
      "local function foo()",
      "  return 1",
      "end",
    }

    menu_case.run_cases({
      {
        "moves cursor to beginning of first parameter",
        fn_two_params,
        1,
        "b",
        supported.parameter,
        "Parameter",
        extras1({
          positioned_at = { lines = fn_two_params, row1 = 1, needle = "a," },
        }),
      },
      {
        "no parameters → surrounding function name",
        fn_empty_params,
        1,
        "(",
        supported.parameter,
        "Parameter",
        extras1({
          positioned_at = { lines = fn_empty_params, row1 = 1, needle = "foo" },
        }),
      },
    })
  end)

  describe("Function body", function()
    local fn_two_stmts = {
      "local function foo()",
      "  local a = 1",
      "  local z = 2",
      "end",
    }

    menu_case.run_cases({
      {
        "resolves to first statement in body",
        fn_two_stmts,
        3,
        "z",
        supported.assignment,
        "Assignment",
        extras1({
          positioned_at = { lines = fn_two_stmts, row1 = 2, needle = "local" },
        }),
      },
    })
  end)

  describe("Function return", function()
    local fn_ret_val = {
      "local function foo()",
      "  return 42",
      "end",
    }
    local fn_ret_bare = {
      "local function foo()",
      "  return",
      "end",
    }

    menu_case.run_cases({
      {
        "expression return → inner expression",
        fn_ret_val,
        2,
        "42",
        supported.fn,
        "Function",
        extras1({
          positioned_at = { lines = fn_ret_val, row1 = 2, needle = "42" },
        }),
      },
      {
        "bare return → surrounding function name",
        fn_ret_bare,
        2,
        "return",
        supported.fn,
        "Function",
        extras1({
          positioned_at = { lines = fn_ret_bare, row1 = 1, needle = "foo" },
        }),
      },
    })
  end)

  describe("Comment", function()
    local commented = {
      "-- needlehere",
      "local x = 1",
    }

    menu_case.run_cases({
      {
        "stays at cursor on comment text",
        commented,
        1,
        "needlehere",
        supported.generic,
        extras1({
          positioned_at = { lines = commented, row1 = 1, needle = "needlehere" },
        }),
      },
    })
  end)
end)
