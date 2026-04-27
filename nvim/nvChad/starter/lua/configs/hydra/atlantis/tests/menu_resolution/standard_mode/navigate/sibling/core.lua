local helpers = require("configs.hydra.atlantis.tests.helpers")
local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

return function()
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
      m.with_navigate_ctx(lines, 4, "secondstmt", function(ctx)
        local inner = nil
        for _, it in ipairs(ctx.nav_column_spec.items or {}) do
          if type(it.label) == "string" and it.label:match("To prev sibling") then
            inner = m.quoted_fragment(it.label)
            break
          end
        end
        assert.truthy(inner, "expected To prev sibling row")
        assert.is_true(inner:match("%.%.%.$") ~= nil, "expected ellipsis in quoted name")
        assert.is_true(vim.fn.strchars(inner:gsub("%.%.%.$", "")) <= 16)
      end, 1)
    end)
  end)

  describe("hotkey, icon, relation phrase, quoted name", function()
    it("formats sibling rows as phrase - quoted target", function()
      m.with_nested_sibling_fixture(function(ctx)
        local prev_row
        for _, it in ipairs(ctx.nav_column_spec.items or {}) do
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
  end)

  describe("nested scope", function()
    it("lists prev/next sibling rows when siblings exist", function()
      m.with_nested_sibling_fixture(function(ctx)
        local has_u, has_i
        for _, it in ipairs(ctx.nav_column_spec.items or {}) do
          if it.key == "u" then has_u = true end
          if it.key == "i" then has_i = true end
        end
        assert.is_true(has_u)
        assert.is_true(has_i)
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
      m.with_navigate_ctx(lines, 4, "b", function(ctx)
        local prev
        for _, it in ipairs(ctx.nav_column_spec.items or {}) do
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
      end, 1)
    end)
  end)
end
