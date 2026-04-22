-- Navigate column: anchor-type-specific item filtering and key schema conformance.

local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

describe("[Atlantis menu] Navigate column", function()
  describe("anchor-type item filtering", function()
    it("omits child navigate row for assignment anchors", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local b = 2",
        "  end",
        "end",
      }
      m.with_navigate_ctx(lines, 3, "b", function(ctx)
        for _, it in ipairs(m.jump_items_with_key(ctx.nav_column_spec.items)) do
          assert.are_not.same("a", it.key)
        end
      end)
    end)
  end)

  describe("key schema conformance", function()
    it("navigate item keys are a subset of schema keys", function()
      m.with_nested_sibling_fixture(function(ctx)
        local allow = m.jump_schema_key_set()
        for _, it in ipairs(m.jump_items_with_key(ctx.nav_column_spec.items)) do
          assert.truthy(allow[it.key], "unexpected navigate key: " .. tostring(it.key))
        end
      end)
    end)
  end)
end)
