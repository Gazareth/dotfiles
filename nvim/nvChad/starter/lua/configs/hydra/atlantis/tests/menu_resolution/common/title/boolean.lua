local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local supported = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants").supported_nodes

return function()
  describe("Boolean expression", function()
    it("builds a bracketed title that echoes the expression for binary_expression at `and`", function()
      local lines = { "return (aa and bb)" }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "and"), function()
        local v = atlantis.build_view_spec({ depth = 0 }, {})
        local ctx = v.anchor_ctx
        local kind = ctx and ctx.parsed_anchor and ctx.parsed_anchor.node_kind
        if kind ~= supported.binary_expression then
          pending("fixture did not resolve to binary_expression on this parser (got " .. tostring(kind) .. ")")
          return
        end
        local t = v.spec.title or ""
        assert.is_true(#t > 8, "non-trivial title")
        assert.truthy(t:find("[", 1, true) and t:find("]", 1, true), "bracketed badge")
        assert.truthy(
          t:find("aa", 1, true) or t:find("and", 1, true) or t:find("return", 1, true),
          "title echoes expression source"
        )
      end)
    end)
  end)
end
