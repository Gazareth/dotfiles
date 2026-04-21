local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")

describe("[Atlantis layout] title — assignment", function()
  it("uses Assignment badge for local binding", function()
    local lines = { "local x = 1" }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
      local v = atlantis.build_view_spec({ depth = 0 }, {})
      local t = v.spec.title or ""
      assert.truthy(t:find("Assignment", 1, true), "semantic badge")
      assert.truthy(t:find("x", 1, true), "lhs name")
    end)
  end)
end)
