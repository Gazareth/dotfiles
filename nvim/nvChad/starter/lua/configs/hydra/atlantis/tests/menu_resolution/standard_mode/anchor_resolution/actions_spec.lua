local helpers = require("configs.hydra.atlantis.tests.helpers")
local supported = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants").supported_nodes
local anchor_build = require("configs.hydra.atlantis.prepare.anchor_point.build")
local anchor_actions = require("configs.hydra.atlantis.prepare.anchor_point.actions")

describe("[Atlantis]", function()
  it("'Inspect' - runs without scheduling Hydra reopen", function()
    local lines = {
      "local function f()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "f"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local ctx = {
        node_info = anchor_ctx.anchor_node_info,
        parsed = anchor_ctx.parsed_anchor,
        cursor_node_info = anchor_ctx.cursor_node_info,
      }
      local run = anchor_actions.build(supported.fn, "inspect", ctx)
      assert.truthy(run)
      assert.has_no.errors(function()
        run()
      end)
    end)
  end)
end)
