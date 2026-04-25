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

    describe("outline item reopen", function()
      -- Finds the first actionable (non-separator) item that follows the section heading
      -- matching heading_text. Used to locate "To next <kind>" outline items.
      local function first_item_after_heading(inter, heading_text)
        local in_section = false
        for _, it in ipairs(inter.items or {}) do
          if it.separator and type(it.label) == "string" and it.label:find(heading_text, 1, true) then
            in_section = true
          end
          if in_section and not it.separator and type(it.action) == "function" then
            return it
          end
        end
      end

      it("navigate item for assignment reopens in standard mode", function()
        local lines = { "local lhs = rhs()" }
        helpers.with_lua(lines, 1, helpers.col0(lines[1], "rhs"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local inter = mr.interact_section(v.spec)
          local item = first_item_after_heading(inter, outline_schema.kind_heading[nk.assignment])
          assert.truthy(item, "expected navigate item under Assignments section")
          assert.is_table(item.reopen)
          assert.is_nil(item.reopen.container_scope, "assignment navigate should reopen in standard mode")
        end)
      end)

      it("navigate item for function declaration reopens in container mode", function()
        local lines = {
          "local function outer()",
          "  local function container_fn()",
          "    local function nested()",
          "    end",
          "  end",
          "end",
        }
        helpers.with_lua(lines, 2, helpers.col0(lines[2], "container_fn"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local inter = mr.interact_section(v.spec)
          local item = first_item_after_heading(inter, outline_schema.kind_heading[nk.declaration])
          assert.truthy(item, "expected navigate item under Declarations section")
          assert.is_table(item.reopen)
          assert.are.equal("current_scope", item.reopen.container_scope,
            "function declaration navigate should reopen in container mode")
        end)
      end)
    end)

    describe("contains only outline items (no anchor actions)", function()
      local function assert_no_action_items(inter)
        for _, it in ipairs(inter.items or {}) do
          assert.is_nil(
            it.action_id,
            "unexpected anchor action in container mode Interact: " .. tostring(it.label or it.heading)
          )
        end
      end

      it("function anchor: no action_id items", function()
        helpers.with_lua(fn_nested, 2, helpers.col0(fn_nested[2], "inner"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          assert_no_action_items(mr.interact_section(v.spec))
        end)
      end)

      it("assignment anchor: no action_id items", function()
        helpers.with_lua(assign_lines, 1, helpers.col0(assign_lines[1], "rhs"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          assert_no_action_items(mr.interact_section(v.spec))
        end)
      end)

      it("boolean expression anchor: no action_id items", function()
        helpers.with_lua(boolean_lines, 1, helpers.col0(boolean_lines[1], "and"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          assert_no_action_items(mr.interact_section(v.spec))
        end)
      end)

      it("root container mode (file scope): no action_id items", function()
        local lines = { "local x = 1" }
        helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
          local v = atlantis.build_view_spec({ container_scope = "top_level", depth = -1 }, {})
          assert_no_action_items(mr.interact_section(v.spec))
        end)
      end)
    end)
  end)
end
