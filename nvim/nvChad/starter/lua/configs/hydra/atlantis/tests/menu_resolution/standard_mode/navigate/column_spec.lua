-- Navigate column: labels, truncation, top-level vs nested visibility, key allowlist, jump_action smoke.

local anchor_build = require("configs.hydra.atlantis.anchor.build")
local atlantis = require("configs.hydra.atlantis")
local hint_mod = require("configs.hydra.lib.hint")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local navigate_cfg = require("configs.hydra.atlantis.schema.menu.navigate")
local walker = require("configs.hydra.atlantis.outline.walker")

describe("[Atlantis menu] Navigate column", function()
  describe("truncation (16 chars + ellipsis)", function()
    it("shortens quoted target names in sibling jump labels", function()
      local nm = "vfirstverylongnameZ"
      assert.is_true(vim.fn.strchars(nm) > 16)
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local " .. nm .. " = 1",
        "    local secondstmt = 2",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "secondstmt"), function()
        local ctx = anchor_build.build({ depth = 0 })
        local inner = nil
        for _, it in ipairs(ctx.navigate_spec.items or {}) do
          if type(it.label) == "string" and it.label:match("To prev sibling") then
            inner = m.quoted_fragment(it.label)
            break
          end
        end
        assert.truthy(inner, "expected To prev sibling row")
        assert.is_true(inner:match("%.%.%.$") ~= nil, "expected ellipsis in quoted name")
        assert.is_true(vim.fn.strchars(inner:gsub("%.%.%.$", "")) <= 16)
      end)
    end)
  end)

  describe("hotkey, icon, relation phrase, quoted name", function()
    it("formats sibling rows as phrase - quoted target", function()
      local lines = {
        "local function f()",
        "  local function g()",
        "    local a = 1",
        "    local b = 2",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "b"), function()
        local ctx = anchor_build.build({ depth = 0 })
        local prev_row
        for _, it in ipairs(ctx.navigate_spec.items or {}) do
          if it.key == "u" then
            prev_row = it
            break
          end
        end
        assert.truthy(prev_row)
        assert.are.same("⬅", prev_row.icon)
        assert.truthy(prev_row.label:match("^To prev sibling %- "))
        assert.truthy(m.quoted_fragment(prev_row.label))
      end)
    end)

    it("shows H/h alias on top-level To top level nav context row in hint text", function()
      local lines = {
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local v = atlantis.build_view_spec({ depth = 0, hotkey_pool = "Hhabcuiwkls1234567890remnpqtz" }, {})
        local opts = vim.tbl_extend("force", { title = v.spec.title }, v.spec.hint_opts or {})
        local built = hint_mod.build(v.spec.sections, opts)
        assert.truthy(built.hint:match("%[H/h%]"))
      end)
    end)
  end)

  describe("top-level statement scope (walker file-scope)", function()
    local function assert_file_scope_navigate_menu()
      local ctx = anchor_build.build({ depth = 0 })
      local bufnr = vim.api.nvim_get_current_buf()
      assert.is_true(
        walker.is_file_scope_anchor(ctx.anchor_node_info and ctx.anchor_node_info.node or nil, bufnr),
        "fixture must produce a file-scope anchor"
      )
      local items = m.jump_items_with_key(ctx.navigate_spec.items)
      local labels = {}
      for _, it in ipairs(items) do
        labels[it.label or ""] = true
      end
      assert.truthy(labels[navigate_cfg.nav_context.to_top_level])
      for _, it in ipairs(items) do
        assert.are_not.same("u", it.key)
        assert.are_not.same("i", it.key)
        assert.are_not.same("a", it.key)
      end
      for _, it in ipairs(ctx.navigate_spec.items or {}) do
        if type(it.label) == "string" then
          assert.is_false(it.label:match("To higher in context") ~= nil)
        end
      end
    end

    it("assignment at file scope yields file-scope-only navigate strip", function()
      local lines = { "local x = 1" }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
        assert_file_scope_navigate_menu()
      end)
    end)
  end)

  describe("nested scope", function()
    it("includes To top level and Current scope nav context rows", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local y = 1",
        "    local z = 2",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "z"), function()
        local ctx = anchor_build.build({ depth = 0 })
        local have_top, have_curr
        for _, it in ipairs(ctx.navigate_spec.items or {}) do
          local lab = it.label
          if type(lab) == "string" then
            if lab:match("^To top level") then
              have_top = true
            end
            if lab:match("^Current scope") then
              have_curr = true
            end
          end
        end
        assert.is_true(have_top)
        assert.is_true(have_curr)
      end)
    end)

    it("lists prev/next sibling rows when siblings exist", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local a = 1",
        "    local b = 2",
        "    local c = 3",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "b"), function()
        local ctx = anchor_build.build({ depth = 0 })
        local has_u, has_i
        for _, it in ipairs(ctx.navigate_spec.items or {}) do
          if it.key == "u" then
            has_u = true
          end
          if it.key == "i" then
            has_i = true
          end
        end
        assert.is_true(has_u)
        assert.is_true(has_i)
      end)
    end)

    it("navigate item keys are a subset of schema keys", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local a = 1",
        "    local b = 2",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "b"), function()
        local ctx = anchor_build.build({ depth = 0 })
        local allow = m.jump_schema_key_set()
        for _, it in ipairs(m.jump_items_with_key(ctx.navigate_spec.items)) do
          assert.truthy(allow[it.key], "unexpected navigate key: " .. tostring(it.key))
        end
      end)
    end)

    it("omits child navigate row for assignment anchors", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local b = 2",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 3, helpers.col0(lines[3], "b"), function()
        local ctx = anchor_build.build({ depth = 0 })
        for _, it in ipairs(m.jump_items_with_key(ctx.navigate_spec.items)) do
          assert.are_not.same("a", it.key)
        end
      end)
    end)
  end)

  describe("jump_action cursor placement", function()
    it("moves cursor to target node start for sibling jump", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local a = 1",
        "    local b = 2",
        "  end",
        "end",
      }
      helpers.with_lua(lines, 4, helpers.col0(lines[4], "b"), function()
        local ctx = anchor_build.build({ depth = 0 })
        local prev
        for _, it in ipairs(ctx.navigate_spec.items or {}) do
          if it.key == "u" and type(it.action) == "function" then
            prev = it
            break
          end
        end
        assert.truthy(prev)
        prev.action()
        local pos = vim.api.nvim_win_get_cursor(0)
        assert.are.same(3, pos[1])
        assert.are.same(helpers.col0(lines[3], "local"), pos[2])
      end)
    end)
  end)
end)
