local helpers = require("configs.hydra.atlantis.tests.helpers")

describe("[Atlantis] menu opens in", function()
  it("anchor mode on function name uses action column title", function()
    local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local atlantis = require("configs.hydra.atlantis")
      local col = require("configs.hydra.atlantis.menu.column_titles")
      local v = atlantis.build_view_spec({}, {})
      assert.is_false(v.container_mode)
      local titles = {}
      for _, sec in ipairs(v.spec.sections or {}) do
        if type(sec) == "table" and type(sec.title) == "string" then
          titles[#titles + 1] = sec.title
        end
      end
      assert.is_true(vim.tbl_contains(titles, col.action()))
    end)
  end)

  it("container mode when prefer_container", function()
    local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 2, 2, function()
      local atlantis = require("configs.hydra.atlantis")
      local v = atlantis.build_view_spec({ prefer_container = true }, {})
      assert.is_true(v.container_mode)
      assert.is_true(#(v.spec.sections or {}) >= 1)
    end)
  end)
end)
