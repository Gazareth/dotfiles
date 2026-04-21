local atlantis = require("configs.hydra.atlantis")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

describe("[Atlantis menu] Create column (container mode)", function()
  it("includes placeholder create actions", function()
    local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 2, helpers.col0(lines[2], "return"), function()
      local v = atlantis.build_view_spec({ container_scope = "current_scope", depth = 0 }, {})
      assert.is_true(v.container_mode)
      local cre = mr.create_section(v.spec)
      assert.truthy(cre)
      assert.are.same(column_titles.create(), cre.title)
      local blob = mr.labels_blob(cre.items)
      assert.truthy(blob:find("placeholder", 1, true))
    end)
  end)
end)
