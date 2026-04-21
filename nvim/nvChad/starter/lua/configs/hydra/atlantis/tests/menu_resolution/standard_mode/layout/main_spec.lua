local atlantis = require("configs.hydra.atlantis")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

describe("[Atlantis layout] main grid", function()
  local lines = {
    "local function foo()",
    "  return 1",
    "end",
  }

  local function assert_three_columns_between_title_and_footer(hint)
    local lines_ = vim.split(hint, "\n")
    assert.is_true(#lines_ >= 4)
    local last = lines_[#lines_]
    assert.truthy(last:find("toggle hint", 1, true))
    local body_end = #lines_ - 2
    local body = table.concat(lines_, "\n", 1, body_end)
    assert.truthy(body:find(" | ", 1, true), "padded column join")
    assert.truthy(body:find(column_titles.navigate(), 1, true))
    assert.truthy(body:find(column_titles.interact(), 1, true))
    assert.truthy(body:find(column_titles.create(), 1, true))
  end

  it("standard mode shows Navigate | Interact | Create between title block and footer", function()
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local v = atlantis.build_view_spec({ depth = 0 }, {})
      assert.is_false(v.container_mode)
      assert_three_columns_between_title_and_footer(mr.build_atlantis_hint_string(v.spec))
    end)
  end)

  it("container mode shows the same three column titles in the body", function()
    helpers.with_lua(lines, 2, helpers.col0(lines[2], "return"), function()
      local v = atlantis.build_view_spec({ container_scope = "current_scope", depth = 0 }, {})
      assert.is_true(v.container_mode)
      assert_three_columns_between_title_and_footer(mr.build_atlantis_hint_string(v.spec))
    end)
  end)
end)
