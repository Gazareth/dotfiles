-- Standard mode: `build_view_spec({}, {})`, non-container hint menu. See assert_resolution.anchor_opts (depth 0).
-- Each case: { test_name, mock_content, test_row, test_needle, node_kind, title?, extras? } — title/extras optional; see menu_case.lua.

local menu_case = require("configs.hydra.atlantis.tests.menu_case")
local supported = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

describe("[Atlantis] (Core)", function()
  describe("Function -", function()
    local fn_default = {
      "local function foo()",
      "  return 1",
      "end",
    }
    local fn_no_body = {
      "local function foo(p)",
      "  return p",
      "end",
    }
    local fn_no_return = {
      "local function foo()",
      "  local y = 1",
      "end",
    }

    menu_case.run_cases({
      { "name", fn_default, 1, "foo", supported.fn, "Function", { sections_include_action_column = true } },
      { "scope", fn_default, 1, "function", supported.fn, "Function" },
      -- Cursor on the parameter name; resolved anchor kind is still Function (not Parameter).
      { "parameters", fn_no_body, 1, "p", supported.fn, "Function" },
      { "body", fn_no_return, 2, "y", supported.assignment, "Assignment" },
      -- Cursor on the return keyword; resolved anchor kind is still Function.
      {
        "Return",
        fn_default,
        2,
        "return",
        supported.fn,
        "Function",
        { positioned_at = { lines = fn_default, row1 = 1, needle = "foo" } },
      },
    })
  end)

  describe("Assignment", function()
    local line_single = { "local x = 1" }
    local rhs_call = { "local x = foo()" }
    local rhs_cond = { "local x = a and b" }

    menu_case.run_cases({
      { "Name (target)", line_single, 1, "x", supported.assignment, "Assignment" },
      { "Scope", line_single, 1, "local", supported.assignment, "Assignment" },
      -- Cursor on assignment value; anchor kind stays Assignment.
      {
        "Value",
        line_single,
        1,
        "1",
        supported.assignment,
        "Assignment",
        { positioned_at = { lines = line_single, row1 = 1, needle = "x" } },
      },
      { "Operator", line_single, 1, "=", supported.assignment, "Assignment" },
      { "Inner function call", rhs_call, 1, "foo", supported.assignment, "Assignment" },
      { "Inner condition", rhs_cond, 1, "and", supported.assignment, "Assignment" },
    })
  end)

  describe("Boolean expression", function()
    local if_and = {
      "if aa and bb then",
      "  return 1",
      "end",
    }
    local if_else = {
      "if x then",
      "  foo()",
      "else",
      "  bar()",
      "end",
    }

    menu_case.run_cases({
      { "On the expression", if_and, 1, "and", supported.generic },
      { "Lhs", if_and, 1, "aa", supported.generic },
      {
        "Rhs",
        if_and,
        1,
        "bb",
        supported.generic,
        {
          positioned_at = { lines = if_and, row1 = 1, needle = "aa" },
        },
      },
      { "Else branch keyword", if_else, 3, "else", supported.generic },
    })
  end)

  describe("Comment — associated construct", function()
    -- Comment lines map to generic for now; tying them to the enclosing construct is later.
    local comment_fn = {
      "-- setup",
      "local function f() end",
    }
    local comment_assign = {
      "-- set",
      "local x = 1",
    }
    local comment_bool = {
      "-- cond",
      "if a and b then",
      "  return",
      "end",
    }

    menu_case.run_cases({
      { "Function", comment_fn, 1, "--", supported.generic },
      { "Assignment", comment_assign, 1, "--", supported.generic },
      { "Boolean expression", comment_bool, 1, "--", supported.generic },
    })
  end)
end)
