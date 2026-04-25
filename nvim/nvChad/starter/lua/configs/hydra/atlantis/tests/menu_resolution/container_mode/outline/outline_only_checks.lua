local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

return function()
  describe("Outline only -", function()
    local function assert_no_action_items(sec)
      for _, it in ipairs(sec.items or {}) do
        assert.is_nil(
          it.action_id,
          "unexpected anchor action in container mode Outline: " .. tostring(it.label or it.heading)
        )
      end
    end

    local menu_opts_nav = { container_scope = "current_scope", depth = 0 }

    local fn_nested = {
      "local function outer()",
      "  local function inner(pa, pb)",
      "    local x = 1",
      "    return x",
      "  end",
      "end",
    }
    local assign_lines = { "local lhs = rhs()" }
    local boolean_lines = {
      "if aa and bb then",
      "  return 1",
      "end",
    }

    it("function anchor: no action_id items", function()
      helpers.with_lua(fn_nested, 2, helpers.col0(fn_nested[2], "inner"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        assert_no_action_items(mr.outline_section(v.spec))
      end)
    end)

    it("assignment anchor: no action_id items", function()
      helpers.with_lua(assign_lines, 1, helpers.col0(assign_lines[1], "rhs"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        assert_no_action_items(mr.outline_section(v.spec))
      end)
    end)

    it("boolean expression anchor: no action_id items", function()
      helpers.with_lua(boolean_lines, 1, helpers.col0(boolean_lines[1], "and"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        assert_no_action_items(mr.outline_section(v.spec))
      end)
    end)

    it("root container mode (file scope): no action_id items", function()
      local lines = { "local x = 1" }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
        local v = atlantis.build_view_spec({ container_scope = "top_level", depth = -1 }, {})
        assert_no_action_items(mr.outline_section(v.spec))
      end)
    end)
  end)
end
