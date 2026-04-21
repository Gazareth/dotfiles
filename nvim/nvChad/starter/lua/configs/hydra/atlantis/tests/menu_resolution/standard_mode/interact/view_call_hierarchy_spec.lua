-- Interact column: view call hierarchy dispatches to namu when present.

local anchor_actions = require("configs.hydra.atlantis.anchor.actions")
local anchor_build = require("configs.hydra.atlantis.anchor.build")
local supported = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes
local helpers = require("configs.hydra.atlantis.tests.helpers")

describe("[Atlantis menu] Interact column - view call hierarchy", function()
  it("delegates to namu.namu_callhierarchy.show_both_calls when available", function()
    local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local calls = 0
      local stub = {
        show_both_calls = function()
          calls = calls + 1
        end,
      }
      local pname = "namu.namu_callhierarchy"
      local prev = package.loaded[pname]
      package.loaded[pname] = stub
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local ctx = {
        node_info = anchor_ctx.anchor_node_info,
        parsed = anchor_ctx.parsed_anchor,
        cursor_node_info = anchor_ctx.cursor_node_info,
      }
      local run = anchor_actions.build(supported.fn, "view_call_hierarchy", ctx)
      assert.truthy(run)
      run()
      package.loaded[pname] = prev
      assert.are.same(1, calls)
    end)
  end)
end)
