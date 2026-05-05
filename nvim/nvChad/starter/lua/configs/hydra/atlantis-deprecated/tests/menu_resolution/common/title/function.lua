local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis-deprecated.tests.helpers")

return function()
  describe("Function", function()
    it("uses Function badge, function name, and scope / parameters / lines metrics", function()
      local lines = {
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local v = atlantis.build_view_spec({ depth = 0 }, {})
        local t = v.spec.title or ""
        assert.truthy(t:find("Function", 1, true), "semantic badge")
        assert.truthy(t:find("foo", 1, true), "name fragment")
        assert.truthy(t:match("%b[]"), "bracketed badge")
        assert.truthy(t:find("{ local, 0 parameters, 3 lines }", 1, true), "function metrics")
      end)
    end)
  end)
end
