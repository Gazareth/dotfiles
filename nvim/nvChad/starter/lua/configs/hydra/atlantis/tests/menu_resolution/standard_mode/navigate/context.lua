local atlantis = require("configs.hydra.atlantis")
local hint_mod = require("configs.hydra.lib.hint")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local navigate_cfg = require("configs.hydra.atlantis.schema.menu.navigate")
local schema_constants = require("configs.hydra.atlantis.schema.constants")

local container_scope = schema_constants.container_scope

local function find_item_with_label(items, label)
  for _, it in ipairs(items or {}) do
    if it.label == label then return it end
  end
end

local function find_go_up_item(items)
  for _, it in ipairs(items or {}) do
    if type(it.reopen) == "table"
      and it.reopen.depth == 0
      and it.reopen.container_scope == nil
      and type(it.action) == "function"
    then
      return it
    end
  end
end

return function()
  describe("Context -", function()
    describe("to top level action", function()
      it("is present for top-level anchors", function()
        m.with_navigate_ctx({ "local x = 1" }, 1, "x", function(ctx)
          local item = find_item_with_label(ctx.nav_column_spec.items, navigate_cfg.nav_context.to_top_level)
          assert.is_not_nil(item, "expected to_top_level item for a file-scope anchor")
        end)
      end)

      it("is present for anchors inside a function", function()
        local lines = {
          "local function outer()",
          "  local x = 1",
          "end",
        }
        m.with_navigate_ctx(lines, 2, "x", function(ctx)
          local item = find_item_with_label(ctx.nav_column_spec.items, navigate_cfg.nav_context.to_top_level)
          assert.is_not_nil(item, "expected to_top_level item even inside a function")
        end)
      end)

      it("reopens in file root container mode", function()
        m.with_navigate_ctx({ "local x = 1" }, 1, "x", function(ctx)
          local item = find_item_with_label(ctx.nav_column_spec.items, navigate_cfg.nav_context.to_top_level)
          assert.is_not_nil(item)
          assert.are.same(container_scope.file, item.reopen.container_scope)
          assert.are.same(-1, item.reopen.depth)
        end)
      end)

      it("jumps cursor to start of the highest surrounding anchor", function()
        local lines = {
          "local function outer()",
          "  local x = 1",
          "end",
        }
        m.with_navigate_ctx(lines, 2, "x", function(ctx)
          local item = find_item_with_label(ctx.nav_column_spec.items, navigate_cfg.nav_context.to_top_level)
          assert.is_not_nil(item)
          item.action()
          local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
          assert.are.same(1, row)
        end)
      end)
    end)

    describe("go up one level action", function()
      it("is absent for top-level anchors", function()
        m.with_navigate_ctx({ "local x = 1" }, 1, "x", function(ctx)
          assert.is_nil(find_go_up_item(ctx.nav_column_spec.items),
            "go up one level should not appear for a top-level anchor")
        end)
      end)

      it("is present when anchor is inside a function", function()
        local lines = {
          "local function outer()",
          "  local x = 1",
          "end",
        }
        m.with_navigate_ctx(lines, 2, "x", function(ctx)
          assert.is_not_nil(find_go_up_item(ctx.nav_column_spec.items),
            "expected go up one level item for anchor inside a function")
        end)
      end)

      it("reopens in standard mode at depth 0", function()
        local lines = {
          "local function outer()",
          "  local x = 1",
          "end",
        }
        m.with_navigate_ctx(lines, 2, "x", function(ctx)
          local item = find_go_up_item(ctx.nav_column_spec.items)
          assert.is_not_nil(item)
          assert.are.same(0, item.reopen.depth)
          assert.is_nil(item.reopen.container_scope)
        end)
      end)

      it("jumps cursor to the next highest anchor point", function()
        local lines = {
          "local function outer()",
          "  local x = 1",
          "end",
        }
        m.with_navigate_ctx(lines, 2, "x", function(ctx)
          local item = find_go_up_item(ctx.nav_column_spec.items)
          assert.is_not_nil(item)
          item.action()
          local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
          assert.are.same(1, row)
        end)
      end)
    end)

    describe("hotkey alias in hint text", function()
      it("shows H/h alias on To top level nav context row", function()
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
  end)
end
