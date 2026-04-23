local nk = require("configs.hydra.atlantis.schema.constants").node_kinds
local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local outline_schema = require("configs.hydra.atlantis.schema.menu.outline")

local menu_opts_nav = { container_scope = "current_scope", depth = 0 }

return function()
  describe("Column", function()
    local fn_nested = {
      "local function outer()",
      "  local function inner(pa, pb)",
      "    local x = 1",
      "    return x",
      "  end",
      "end",
    }

    it("function anchor shows Declarations group", function()
      helpers.with_lua(fn_nested, 2, helpers.col0(fn_nested[2], "inner"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local inter = mr.interact_section(v.spec)
        assert.truthy(inter)
        local blob = mr.labels_blob(inter.items)
        assert.truthy(blob:find(outline_schema.kind_heading[nk.declaration], 1, true))
      end)
    end)

    it("function body anchor shows actionable items", function()
      local solo = {
        "local function solo()",
        "  local x = 1",
        "  return x",
        "end",
      }
      helpers.with_lua(solo, 2, helpers.col0(solo[2], "x"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local inter = mr.interact_section(v.spec)
        assert.truthy(inter)
        assert.is_true(#inter.items >= 3)
        local blob = mr.labels_blob(inter.items)
        assert.truthy(not blob:find("No actionable nodes", 1, true), "outline should classify body children")
      end)
    end)

    local assign_lines = { "local lhs = rhs()" }
    it("assignment anchor shows Assignments group", function()
      helpers.with_lua(assign_lines, 1, helpers.col0(assign_lines[1], "rhs"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local inter = mr.interact_section(v.spec)
        local blob = mr.labels_blob(inter.items)
        assert.truthy(blob:find(outline_schema.kind_heading[nk.assignment], 1, true))
      end)
    end)

    local boolean_lines = {
      "if aa and bb then",
      "  return 1",
      "end",
    }
    it("boolean expression anchor shows Control flow or Keywords group", function()
      helpers.with_lua(boolean_lines, 1, helpers.col0(boolean_lines[1], "and"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local inter = mr.interact_section(v.spec)
        local blob = mr.labels_blob(inter.items)
        assert.truthy(
          blob:find(outline_schema.kind_heading[nk.control_frame], 1, true)
            or blob:find(outline_schema.kind_heading[nk.keyword], 1, true)
        )
      end)
    end)
  end)
end
