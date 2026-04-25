local atlantis = require("configs.hydra.atlantis")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

return function()
  local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }

    local function assert_three_columns_between_title_and_footer(hint, is_container)
      local lines_ = vim.split(hint, "\n")
      assert.is_true(#lines_ >= 4)
      local last = lines_[#lines_]
      assert.truthy(last:find("toggle hint", 1, true))
      local body_end = #lines_ - 2
      local body = table.concat(lines_, "\n", 1, body_end)
      assert.truthy(body:find(" | ", 1, true), "padded column join")
      assert.truthy(body:find(column_titles.navigate(), 1, true))
      if is_container then
        assert.truthy(body:find(column_titles.outline(), 1, true))
      else
        assert.truthy(body:find(column_titles.interact(), 1, true))
      end
      assert.truthy(body:find(column_titles.create(), 1, true))
    end

    it("standard mode shows Navigate | Interact | Create between title block and footer", function()
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local v = atlantis.build_view_spec({ depth = 0 }, {})
        assert.is_false(v.container_mode)
        assert_three_columns_between_title_and_footer(mr.build_atlantis_hint_string(v.spec), false)
      end)
    end)

    it("container mode shows the same three column titles in the body", function()
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "return"), function()
        local v = atlantis.build_view_spec({ container_scope = "current_scope", depth = 0 }, {})
        assert.is_true(v.container_mode)
        assert_three_columns_between_title_and_footer(mr.build_atlantis_hint_string(v.spec), true)
      end)
    end)

    it("uses Navigate, Outline, and Create columns with items in each", function()
      local nested = {
        "local function outer()",
        "  local function inner(a, b)",
        "    local x = 1",
        "    return x",
        "  end",
        "end",
      }
      helpers.with_lua(nested, 3, helpers.col0(nested[3], "x"), function()
        local v = atlantis.build_view_spec({ container_scope = "current_scope", depth = 0 }, {})
        assert.is_true(v.container_mode)
        local titles = {}
        for _, sec in ipairs(v.spec.sections or {}) do
          if type(sec) == "table" and type(sec.title) == "string" then
            titles[#titles + 1] = sec.title
          end
        end
        assert.is_true(vim.tbl_contains(titles, column_titles.navigate()))
        assert.is_true(vim.tbl_contains(titles, column_titles.outline()))
        assert.is_true(vim.tbl_contains(titles, column_titles.create()))
        local nav = mr.navigate_section(v.spec)
        local outl = mr.outline_section(v.spec)
        local cre = mr.create_section(v.spec)
        assert.truthy(nav and nav.items)
        assert.truthy(outl and outl.items)
        assert.truthy(cre and cre.items)
      end)
    end)
end
