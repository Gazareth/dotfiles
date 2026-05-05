local atlantis = require("configs.hydra.atlantis")
local column_titles = require("configs.hydra.atlantis-deprecated.menu.column_titles")
local helpers = require("configs.hydra.atlantis-deprecated.tests.helpers")
local mr = require("configs.hydra.atlantis-deprecated.tests.menu_resolution.helpers")

return function()
  describe("Placeholder -", function()
    it("includes placeholder create actions", function()
      local lines = {
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local v = atlantis.build_view_spec({ depth = 0 }, {})
        assert.is_false(v.container_mode)
        local cre = mr.create_section(v.spec)
        assert.truthy(cre)
        assert.are.same(column_titles.create(), cre.title)
        local blob = mr.labels_blob(cre.items)
        assert.truthy(blob:find("placeholder", 1, true))
      end)
    end)
  end)
end
