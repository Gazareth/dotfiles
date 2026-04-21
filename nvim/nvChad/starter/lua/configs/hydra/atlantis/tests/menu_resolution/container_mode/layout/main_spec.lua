local atlantis = require("configs.hydra.atlantis")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

local menu_opts_nav = { prefer_container = true, depth = 0 }

describe("[Atlantis layout] main grid (container mode)", function()
  it("uses Navigate, Interact, and Create columns with items in each", function()
    local lines = {
      "local function outer()",
      "  local function inner(a, b)",
      "    local x = 1",
      "    return x",
      "  end",
      "end",
    }
    helpers.with_lua(lines, 3, helpers.col0(lines[3], "x"), function()
      local v = atlantis.build_view_spec(menu_opts_nav, {})
      assert.is_true(v.container_mode)
      local titles = {}
      for _, sec in ipairs(v.spec.sections or {}) do
        if type(sec) == "table" and type(sec.title) == "string" then
          titles[#titles + 1] = sec.title
        end
      end
      assert.is_true(vim.tbl_contains(titles, column_titles.navigate()))
      assert.is_true(vim.tbl_contains(titles, column_titles.interact()))
      assert.is_true(vim.tbl_contains(titles, column_titles.create()))
      local nav = mr.navigate_section(v.spec)
      local inter = mr.interact_section(v.spec)
      local cre = mr.create_section(v.spec)
      assert.truthy(nav and nav.items)
      assert.truthy(inter and inter.items)
      assert.truthy(cre and cre.items)
    end)
  end)
end)
