local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

return function()
  describe("Footer", function()
    local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }

    local function assert_default_footer(hint)
      local lines_ = vim.split(hint, "\n")
      assert.is_true(#lines_ >= 2, "hint should have a rule line and footer row")
      local last = lines_[#lines_]
      assert.truthy(last:find("[?] toggle hint", 1, true), "toggle hint copy")
      assert.truthy(last:find("[q]/[Esc] exit", 1, true), "exit copy")
      local rule = lines_[#lines_ - 1]
      assert.truthy(rule:match("^%-+"), "horizontal rule before footer")
    end

    it("standard mode uses default Hydra footer strings", function()
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local v = atlantis.build_view_spec({ depth = 0 }, {})
        assert.is_false(v.container_mode)
        assert_default_footer(mr.build_atlantis_hint_string(v.spec))
      end)
    end)

    it("container mode uses the same default footer strings", function()
      helpers.with_lua(lines, 2, helpers.col0(lines[2], "return"), function()
        local v = atlantis.build_view_spec({ container_scope = "current_scope", depth = 0 }, {})
        assert.is_true(v.container_mode)
        assert_default_footer(mr.build_atlantis_hint_string(v.spec))
      end)
    end)
  end)
end
