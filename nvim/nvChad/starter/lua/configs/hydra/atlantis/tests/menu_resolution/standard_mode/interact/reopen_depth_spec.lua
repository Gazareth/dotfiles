-- Interact column items carry explicit reopen.depth baked in at build time.

local anchor_build = require("configs.hydra.atlantis.anchor.build")
local render_spec = require("configs.hydra.atlantis.menu.render_spec")
local helpers = require("configs.hydra.atlantis.tests.helpers")

describe("[Atlantis menu] Interact column - reopen depth", function()
  local function find_action_row(rs, action_id)
    for _, r in ipairs(rs.action_rows or {}) do
      if r.action_id == action_id then
        return r
      end
    end
  end

  it("jump_to_body row has reopen.depth = current_depth + 1", function()
    local lines = {
      "local function foo()",
      "  local x = 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local rs = render_spec.build(anchor_ctx)
      local row = find_action_row(rs, "jump_to_body")
      assert.truthy(row, "expected jump_to_body row")
      assert.is_table(row.reopen, "jump_to_body must carry explicit reopen args")
      assert.are.same(1, row.reopen.depth)
    end)
  end)

  it("jump_to_parameter row has reopen.depth = current_depth + 1", function()
    local lines = {
      "local function foo(a)",
      "  return a",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local rs = render_spec.build(anchor_ctx)
      local row = find_action_row(rs, "jump_to_parameter")
      assert.truthy(row, "expected jump_to_parameter row")
      assert.is_table(row.reopen, "jump_to_parameter must carry explicit reopen args")
      assert.are.same(1, row.reopen.depth)
    end)
  end)

  it("rescope row has no reopen (closes menu)", function()
    local lines = {
      "local function foo()",
      "  local x = 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local rs = render_spec.build(anchor_ctx)
      local row = find_action_row(rs, "rescope")
      if row then
        assert.is_nil(row.reopen, "rescope must not carry reopen args")
      end
    end)
  end)
end)
