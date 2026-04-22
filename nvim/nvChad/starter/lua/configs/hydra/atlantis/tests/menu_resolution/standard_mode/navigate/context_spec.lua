-- Navigate column: which context nav items appear (file-scope vs nested), and hint text.

local atlantis = require("configs.hydra.atlantis")
local hint_mod = require("configs.hydra.lib.hint")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local navigate_cfg = require("configs.hydra.atlantis.schema.menu.navigate")
local walker = require("configs.hydra.atlantis.prepare.anchor_container.scope_resolver")

describe("[Atlantis menu] Navigate column", function()
  describe("top-level statement scope (walker file-scope)", function()
    local function assert_file_scope_navigate_menu(ctx)
      local bufnr = vim.api.nvim_get_current_buf()
      assert.is_true(
        walker.is_file_scope_anchor(ctx.anchor_node_info and ctx.anchor_node_info.node or nil, bufnr),
        "fixture must produce a file-scope anchor"
      )
      local items = m.jump_items_with_key(ctx.nav_column_spec.items)
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
      for _, it in ipairs(ctx.nav_column_spec.items or {}) do
        if type(it.label) == "string" then
          assert.is_false(it.label:match("To higher in context") ~= nil)
        end
      end
    end

    it("assignment at file scope yields file-scope-only navigate strip", function()
      m.with_navigate_ctx({ "local x = 1" }, 1, "x", assert_file_scope_navigate_menu)
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
      m.with_navigate_ctx(lines, 4, "z", function(ctx)
        local have_top, have_curr
        for _, it in ipairs(ctx.nav_column_spec.items or {}) do
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
