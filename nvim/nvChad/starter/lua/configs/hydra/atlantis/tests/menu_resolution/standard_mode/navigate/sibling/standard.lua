local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

return function()
  describe("Standard Anchor Only -", function()
    it("skips non-actionable nodes (do-end blocks) when jumping to next sibling", function()
      local lines = {
        "local function f()",
        "  local a = 1",
        "  do end",
        "  local b = 2",
        "end",
      }
      -- Cursor on 'local a = 1' (row 2)
      m.with_navigate_ctx(lines, 2, "a", function(ctx)
        local items = ctx.nav_column_spec.items
        local next_item = m.find_item_by_key(items, "i")

        assert.truthy(next_item, "expected key 'i' item for next sibling")
        -- Assignment labels show the LHS name only, so check for "b" not the full statement.
        assert.truthy(
          next_item.label:find('"b"', 1, true),
          "expected next sibling to skip do-end block and target 'b' (local b = 2), got: " .. tostring(next_item.label)
        )
      end, 1)
    end)

    it("ensures siblings share a common parent standard anchor (nested scope)", function()
      local lines = {
        "local function outer()",
        "  local a = 1",
        "  if true then",
        "    local b = 2",
        "  end",
        "end",
      }
      -- Cursor on 'local a = 1' (row 2). Next sibling should be 'if true then', NOT 'local b = 2'.
      m.with_navigate_ctx(lines, 2, "a", function(ctx)
        local items = ctx.nav_column_spec.items
        local next_item = m.find_item_by_key(items, "i")

        assert.truthy(next_item, "expected key 'i' item")
        assert.truthy(
          next_item.label:find("if true then", 1, true),
          "expected next sibling to be 'if true then', got: " .. tostring(next_item.label)
        )
      end, 1)
    end)
  end)
end
