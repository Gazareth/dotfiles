local m = require("configs.hydra.atlantis-deprecated.tests.menu_resolution.helpers")
local navigate_schema = require("configs.hydra.atlantis-deprecated.schema.menu.navigate")

return function()
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

    describe("nested (inside function body)", function()
      local complex_declaration = {
        "local function f()",
        "  local a = 1",
        "  local b = 2",
        "  if true then",
        "    local x = 1",
        "  end",
        "  local c = 3",
        "  local function inner()",
        "    local y = 2",
        "  end",
        "end",
      }

      it("last statement shows 'To first sibling' on key i", function()
        m.with_navigate_ctx(complex_declaration, 8, "inner", function(ctx)
          local item = m.find_item_by_key(ctx.nav_column_spec.items, "i")
          assert.truthy(item)
          assert.truthy(item.label:find(navigate_schema.relation_phrase.first_sibling, 1, true))
        end, 1)
      end)

      it("last statement first_sibling action moves cursor to first statement in function body", function()
        m.with_navigate_ctx(complex_declaration, 8, "inner", function(ctx)
          local item = m.find_item_by_key(ctx.nav_column_spec.items, "i")
          assert.truthy(item)
          item.action()
          assert.are.same(2, vim.api.nvim_win_get_cursor(0)[1])
        end, 1)
      end)

      it("first statement shows 'To last sibling' on key u", function()
        m.with_navigate_ctx(complex_declaration, 2, "a", function(ctx)
          local item = m.find_item_by_key(ctx.nav_column_spec.items, "u")
          assert.truthy(item)
          assert.truthy(item.label:find(navigate_schema.relation_phrase.last_sibling, 1, true))
        end, 1)
      end)

      it("first statement last_sibling action moves cursor to last statement in function body", function()
        m.with_navigate_ctx(complex_declaration, 2, "a", function(ctx)
          local item = m.find_item_by_key(ctx.nav_column_spec.items, "u")
          assert.truthy(item)
          item.action()
          assert.are.same(8, vim.api.nvim_win_get_cursor(0)[1])
        end, 1)
      end)

      it("wraps between parameters in a parameter list", function()
        local params = { "local function f(x, y, z) end" }
        m.with_navigate_ctx(params, 1, "z", function(ctx)
          local item = m.find_item_by_key(ctx.nav_column_spec.items, "i")
          assert.truthy(item)
          assert.truthy(item.label:find(navigate_schema.relation_phrase.first_sibling, 1, true))
        end)
      end)
    end)
  end)
end
