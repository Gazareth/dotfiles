local nk = require("configs.hydra.atlantis.schema.constants").node_kinds
local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local outline_schema = require("configs.hydra.atlantis.schema.menu.outline")

local menu_opts_nav = { container_scope = "current_scope", depth = 0 }

return function()
  describe("Reopen -", function()
    local nested = {
      "local function outer()",
      "  local function inner(a, b)",
      "    local x = 1",
      "    local y = 2",
      "    return x",
      "  end",
      "end",
    }

    describe("Navigate column", function()
      it("sibling nav item carries reopen without container_scope (standard reopen)", function()
        helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local nav = mr.navigate_section(v.spec)
          local item = mr.find_item_by_key(nav.items, "u") or mr.find_item_by_key(nav.items, "i")
          assert.truthy(item, "expected sibling nav row")
          assert.is_table(item.reopen, "sibling item must have explicit reopen args")
          assert.is_number(item.reopen.depth)
          assert.is_nil(item.reopen.container_scope, "sibling nav should reopen in standard mode")
        end)
      end)

      it("child nav item carries container_scope when already in container mode", function()
        helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local nav = mr.navigate_section(v.spec)
          local item = mr.find_item_by_key(nav.items, "o") or mr.find_item_by_key(nav.items, "l")
          if not item then
            return
          end
          assert.is_table(item.reopen, "child item must have explicit reopen args")
          assert.are.equal("current_scope", item.reopen.container_scope)
        end)
      end)

      it("navigate-to-container item carries container_scope and no action mutation", function()
        helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local nav = mr.navigate_section(v.spec)
          local item_H = mr.find_item_by_key(nav.items, "H")
          local item_h = mr.find_item_by_key(nav.items, "h")
          if item_H then
            assert.is_table(item_H.reopen)
            assert.is_string(item_H.reopen.container_scope)
          end
          if item_h then
            assert.is_table(item_h.reopen)
            assert.are.equal("current_scope", item_h.reopen.container_scope)
          end
        end)
      end)
    end)

    describe("Outline column", function()
      local function first_item_after_heading(sec, heading_text)
        local in_section = false
        for _, it in ipairs(sec.items or {}) do
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
          local sec = mr.outline_section(v.spec)
          local item = first_item_after_heading(sec, outline_schema.kind_heading[nk.assignment])
          assert.truthy(item, "expected navigate item under Assignments section")
          assert.is_table(item.reopen)
          assert.is_nil(item.reopen.container_scope, "assignment navigate should reopen in standard mode")
        end)
      end)

      it("navigate item for function declaration reopens in standard mode", function()
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
          local sec = mr.outline_section(v.spec)
          local item = first_item_after_heading(sec, outline_schema.kind_heading[nk.declaration])
          assert.truthy(item, "expected navigate item under Declarations section")
          assert.is_table(item.reopen)
          assert.is_nil(item.reopen.container_scope,
            "function declaration navigate should reopen in standard mode")
        end)
      end)
    end)
  end)
end
