local helpers = require("configs.hydra.atlantis.tests.helpers")
local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local navigate_schema = require("configs.hydra.atlantis.schema.menu.navigate")

return function()
  describe("Sibling -", function()
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
        end)
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
    end)

    describe("wrap-around", function()
      -- Three file-level statements: cursor on last (c) or first (a) to test
      -- wrap-around jumps across to the non-adjacent extreme end.
      local three_stmts = {
        "local a = 1",
        "local b = 2",
        "local c = 3",
      }

      it("last anchor shows 'To first sibling' on key i instead of next sibling", function()
        m.with_navigate_ctx(three_stmts, 3, "c", function(ctx)
          local item
          for _, it in ipairs(ctx.nav_column_spec.items or {}) do
            if it.key == "i" and type(it.label) == "string" then
              item = it
              break
            end
          end
          assert.truthy(item, "expected key i item for last anchor")
          assert.truthy(
            item.label:find(navigate_schema.relation_phrase.first_sibling, 1, true),
            "expected 'To first sibling' label, got: " .. tostring(item.label)
          )
        end)
      end)

      it("last anchor first_sibling action moves cursor to first statement", function()
        m.with_navigate_ctx(three_stmts, 3, "c", function(ctx)
          local item
          for _, it in ipairs(ctx.nav_column_spec.items or {}) do
            if it.key == "i" and type(it.action) == "function" then
              item = it
              break
            end
          end
          assert.truthy(item)
          item.action()
          assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
        end)
      end)

      it("first anchor shows 'To last sibling' on key u instead of prev sibling", function()
        m.with_navigate_ctx(three_stmts, 1, "a", function(ctx)
          local item
          for _, it in ipairs(ctx.nav_column_spec.items or {}) do
            if it.key == "u" and type(it.label) == "string" then
              item = it
              break
            end
          end
          assert.truthy(item, "expected key u item for first anchor")
          assert.truthy(
            item.label:find(navigate_schema.relation_phrase.last_sibling, 1, true),
            "expected 'To last sibling' label, got: " .. tostring(item.label)
          )
        end)
      end)

      it("first anchor last_sibling action moves cursor to last statement", function()
        m.with_navigate_ctx(three_stmts, 1, "a", function(ctx)
          local item
          for _, it in ipairs(ctx.nav_column_spec.items or {}) do
            if it.key == "u" and type(it.action) == "function" then
              item = it
              break
            end
          end
          assert.truthy(item)
          item.action()
          assert.are.same(3, vim.api.nvim_win_get_cursor(0)[1])
        end)
      end)

      it("middle anchor shows normal prev/next sibling (no wrap-around items)", function()
        local three_stmts = { "local a = 1", "local b = 2", "local c = 3" }
        m.with_navigate_ctx(three_stmts, 2, "b", function(ctx)
          local blob = m.labels_blob(ctx.nav_column_spec.items)
          assert.truthy(blob:find(navigate_schema.relation_phrase.prev_sibling, 1, true))
          assert.truthy(blob:find(navigate_schema.relation_phrase.next_sibling, 1, true))
          assert.is_falsy(blob:find(navigate_schema.relation_phrase.first_sibling, 1, true))
          assert.is_falsy(blob:find(navigate_schema.relation_phrase.last_sibling, 1, true))
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
        end)
      end)
    end)
  end)
end
