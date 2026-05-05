local anchor_build = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build")
local render_spec = require("configs.hydra.atlantis-deprecated.menu.render_spec")
local helpers = require("configs.hydra.atlantis-deprecated.tests.helpers")
local m = require("configs.hydra.atlantis-deprecated.tests.menu_resolution.helpers")

local function find_action_row(rs, action_id)
  for _, r in ipairs(rs.action_rows or {}) do
    if r.action_id == action_id then return r end
  end
end

return function()
  describe("Comment interact action -", function()
    it("appears on a function with a preceding comment", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        assert.truthy(find_action_row(rs, "jump_to_comment"),
          "expected jump_to_comment row when comment precedes the anchor")
      end)
    end)

    it("is absent when a function has no preceding comment", function()
      local lines = {
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        assert.is_nil(find_action_row(rs, "jump_to_comment"),
          "jump_to_comment must not appear when no comment precedes the anchor")
      end)
    end)

    it("is absent when a non-comment statement precedes the anchor", function()
      local lines = {
        "local a = 1",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        assert.is_nil(find_action_row(rs, "jump_to_comment"),
          "jump_to_comment must not appear when preceding sibling is not a comment")
      end)
    end)

    it("appears on an assignment inside a function body with a preceding comment", function()
      local lines = {
        "local function outer()",
        "  -- note",
        "  local x = 1",
        "end",
      }
      helpers.with_lua(lines, 3, helpers.col0(lines[3], "x"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 1 }))
        assert.truthy(find_action_row(rs, "jump_to_comment"),
          "expected jump_to_comment row for nested statement preceded by comment")
      end)
    end)

    it("jumps cursor to the comment's start row", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_comment")
        assert.truthy(row)
        row.action()
        assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
      end)
    end)

    it("jumps cursor to the FIRST line of a multi-line comment block", function()
      local lines = {
        "-- line 1",
        "-- line 2",
        "-- line 3",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_comment")
        assert.truthy(row)
        row.action()
        assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
      end)
    end)

    it("reopen depth is the same as the current depth", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_comment")
        assert.truthy(row)
        assert.is_table(row.reopen)
        assert.are.same(0, row.reopen.depth)
      end)
    end)

    it("label is 'Comment'", function()
      local lines = {
        "-- docs",
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "foo"), function()
        local rs = render_spec.build(anchor_build.build({ depth = 0 }))
        local row = find_action_row(rs, "jump_to_comment")
        assert.truthy(row)
        assert.are.same("Comment", row.label)
      end)
    end)
  end)
end
