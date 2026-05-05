local anchor_build = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build")
local render_spec = require("configs.hydra.atlantis-deprecated.menu.render_spec")
local helpers = require("configs.hydra.atlantis-deprecated.tests.helpers")

local function find_action_row(rs, action_id)
  for _, r in ipairs(rs.action_rows or {}) do
    if r.action_id == action_id then return r end
  end
end

return function()
  describe("Jump to commented statement (from comment anchor) -", function()
    it("appears when the comment immediately precedes a statement", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      -- Position cursor on the comment node itself
      helpers.with_lua(lines, 1, 0, function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        assert.truthy(find_action_row(rs, "jump_to_commented_statement"),
          "expected jump_to_commented_statement row when comment precedes a statement")
      end)
    end)

    it("is absent for a trailing comment with no following statement", function()
      local lines = {
        "local function foo()",
        "  return 1",
        "end",
        "-- trailing",
      }
      helpers.with_lua(lines, 4, 0, function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        assert.is_nil(find_action_row(rs, "jump_to_commented_statement"),
          "jump_to_commented_statement must not appear when no statement follows")
      end)
    end)

    it("jumps cursor to the associated statement", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, 0, function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_commented_statement")
        assert.truthy(row)
        row.action()
        assert.are.same(2, vim.api.nvim_win_get_cursor(0)[1])
      end)
    end)

    it("skips over additional comment lines to reach the first non-comment statement", function()
      local lines = {
        "-- line 1",
        "-- line 2",
        "local function foo()",
        "  return 1",
        "end",
      }
      -- Cursor on the first comment line
      helpers.with_lua(lines, 1, 0, function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_commented_statement")
        assert.truthy(row)
        row.action()
        assert.are.same(3, vim.api.nvim_win_get_cursor(0)[1])
      end)
    end)

    it("label is 'Jump to statement'", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, 0, function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_commented_statement")
        assert.truthy(row)
        assert.are.same("Jump to statement", row.label)
      end)
    end)
  end)
end
