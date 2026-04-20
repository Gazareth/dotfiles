-- Nav / outline menu: jump + Navigate columns, reopen semantics.

local nk = require("configs.hydra.atlantis.schema.constants").node_kinds
local atlantis = require("configs.hydra.atlantis")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local nav_helpers = require("configs.hydra.atlantis.tests.navigation.nav_helpers")
local outline_schema = require("configs.hydra.atlantis.schema.menu.outline")

local menu_opts_nav = { prefer_container = true, depth = 0 }

describe("[Nav menu]", function()
  describe("container_mode and section layout", function()
    it("uses outline spec with Jump and Navigate columns", function()
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
        assert.is_true(vim.tbl_contains(titles, column_titles.jump()))
        assert.is_true(vim.tbl_contains(titles, column_titles.navigate()))
        local jmp = nav_helpers.jump_section(v.spec)
        local nav = nav_helpers.navigate_section(v.spec)
        assert.truthy(jmp and jmp.items)
        assert.truthy(nav and nav.items)
      end)
    end)
  end)

  describe("common jump keys", function()
    local nested = {
      "local function outer()",
      "  local function inner(a, b)",
      "    local x = 1",
      "    local y = 2",
      "    return x",
      "  end",
      "end",
    }

    it("exposes only keys from jump schema (nested scope)", function()
      helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        assert.is_true(v.container_mode)
        local jmp = nav_helpers.jump_section(v.spec)
        local have = nav_helpers.collect_keys(jmp.items)
        local allowed = nav_helpers.jump_schema_key_set()
        for k in pairs(have) do
          assert.is_true(allowed[k], "unexpected jump key: " .. tostring(k))
        end
        assert.is_true(have["H"] or have["h"], "expected navigation keys")
        assert.is_true(have["u"] or have["i"], "expected sibling jump keys when siblings exist")
      end)
    end)
  end)

  describe("Navigate column structure", function()
    local fn_nested = {
      "local function outer()",
      "  local function inner(pa, pb)",
      "    local x = 1",
      "    return x",
      "  end",
      "end",
    }

    it("Function anchor lists Declarations when container includes parameters", function()
      -- Nested callable: container is the inner function_declaration; cursor on signature lists params.
      helpers.with_lua(fn_nested, 2, helpers.col0(fn_nested[2], "inner"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local nav = nav_helpers.navigate_section(v.spec)
        assert.truthy(nav)
        local blob = nav_helpers.navigate_labels_blob(nav.items)
        assert.truthy(blob:find(outline_schema.kind_heading[nk.declaration], 1, true))
      end)
    end)

    it("top-level callable body lists actionable outline rows in Navigate", function()
      local solo = {
        "local function solo()",
        "  local x = 1",
        "  return x",
        "end",
      }
      helpers.with_lua(solo, 2, helpers.col0(solo[2], "x"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local nav = nav_helpers.navigate_section(v.spec)
        assert.truthy(nav)
        assert.is_true(#nav.items >= 3)
        local blob = nav_helpers.navigate_labels_blob(nav.items)
        assert.truthy(not blob:find("No actionable nodes", 1, true), "outline should classify body children")
      end)
    end)

    local assign_lines = { "local lhs = rhs()" }
    it("Assignment anchor surfaces Assignments in Navigate", function()
      helpers.with_lua(assign_lines, 1, helpers.col0(assign_lines[1], "rhs"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local nav = nav_helpers.navigate_section(v.spec)
        local blob = nav_helpers.navigate_labels_blob(nav.items)
        assert.truthy(blob:find(outline_schema.kind_heading[nk.assignment], 1, true))
      end)
    end)

    local boolean_lines = {
      "if aa and bb then",
      "  return 1",
      "end",
    }
    it("Boolean expression anchor surfaces Control flow / Keywords in Navigate", function()
      helpers.with_lua(boolean_lines, 1, helpers.col0(boolean_lines[1], "and"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local nav = nav_helpers.navigate_section(v.spec)
        local blob = nav_helpers.navigate_labels_blob(nav.items)
        assert.truthy(
          blob:find(outline_schema.kind_heading[nk.control_frame], 1, true)
            or blob:find(outline_schema.kind_heading[nk.keyword], 1, true)
        )
      end)
    end)
  end)

  describe("reopen behavior", function()
    local nested = {
      "local function outer()",
      "  local function inner(a, b)",
      "    local x = 1",
      "    local y = 2",
      "    return x",
      "  end",
      "end",
    }

    it("prev sibling jump clears container flags (standard menu)", function()
      helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        local jmp = nav_helpers.jump_section(v.spec)
        local item = nav_helpers.find_jump_item_by_key(jmp.items, "u")
        assert.truthy(item, "expected prev sibling row")
        local captured, restore = nav_helpers.stub_atlantis_open()
        item.action(item)
        vim.wait(400, function()
          return #captured > 0
        end)
        restore()
        assert.is_true(#captured >= 1)
        local mo = captured[1].menu_opts
        assert.is_nil(mo.prefer_container)
        assert.is_nil(mo._atlantis_container_session)
      end)
    end)

    it("wrapped reopen keeps container flags when item sets _preserve_container_on_reopen", function()
      local captured, restore = nav_helpers.stub_atlantis_open()
      local session = {
        menu_opts = vim.tbl_extend("force", {}, menu_opts_nav),
        hydra_opts = {},
      }
      session.menu_opts.prefer_container = true
      session.menu_opts._atlantis_container_session = true
      local item = {
        _atlantis_reopen_anchor_mode = true,
        _preserve_container_on_reopen = true,
        _reopen_atlantis = 0,
        action = function() end,
      }
      atlantis_action.wrap_item(item, session)
      item.action(item)
      vim.wait(400, function()
        return #captured > 0
      end)
      restore()
      assert.is_true(#captured >= 1)
      local mo = captured[1].menu_opts
      assert.is_true(mo._atlantis_container_session == true or mo.prefer_container == true)
    end)
  end)
end)
