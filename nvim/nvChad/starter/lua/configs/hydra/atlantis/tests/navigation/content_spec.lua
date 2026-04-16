local helpers = require("configs.hydra.atlantis.tests.helpers")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")

describe("[Nav menu] content", function()
  it("includes navigate column for nested function body", function()
    local lines = {
      "local function outer()",
      "  local function inner()",
      "    local y = 1",
      "  end",
      "end",
    }
    helpers.with_lua(lines, 3, helpers.col0(lines[3], "y"), function()
      local atlantis = require("configs.hydra.atlantis")
      local v = atlantis.build_view_spec({ prefer_container = true }, {})
      assert.is_true(v.container_mode)
      local titles = {}
      for _, sec in ipairs(v.spec.sections or {}) do
        if type(sec) == "table" and type(sec.title) == "string" then
          titles[#titles + 1] = sec.title
        end
      end
      assert.is_true(vim.tbl_contains(titles, column_titles.navigate()))
    end)
  end)

  it("nav spec has at least one section with menu items", function()
    local lines = {
      "local a = 1",
      "local b = 2",
      "local function foo()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 4, 2, function()
      local atlantis = require("configs.hydra.atlantis")
      local v = atlantis.build_view_spec({ prefer_container = true }, {})
      assert.is_true(v.container_mode)
      local max_items = 0
      for _, sec in ipairs(v.spec.sections or {}) do
        if type(sec) == "table" and type(sec.items) == "table" then
          max_items = math.max(max_items, #sec.items)
        end
      end
      assert.is_true(max_items >= 1)
    end)
  end)
end)
