local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local navigate_cfg = require("configs.hydra.atlantis.schema.menu.navigate")

local function has_separator_with_label(items, label)
  for _, it in ipairs(items or {}) do
    if it.separator and it.label == label then
      return true
    end
  end
  return false
end

local function has_separator_matching(items, pattern)
  for _, it in ipairs(items or {}) do
    if it.separator and type(it.label) == "string" and it.label:match(pattern) then
      return true
    end
  end
  return false
end

return function()
  describe("Layout -", function()
    describe("section layout", function()
      it("has nav context section", function()
        m.with_all_sections_fixture(function(ctx)
          assert.truthy(has_separator_with_label(ctx.nav_column_spec.items, navigate_cfg.group_labels.nav_context))
        end)
      end)

      it("has anchor-specific section", function()
        m.with_all_sections_fixture(function(ctx)
          assert.truthy(has_separator_matching(ctx.nav_column_spec.items, "^ ↥ "))
        end)
      end)

      it("has sibling section", function()
        m.with_all_sections_fixture(function(ctx)
          assert.truthy(has_separator_with_label(ctx.nav_column_spec.items, navigate_cfg.group_labels.sibling))
        end)
      end)
    end)
  end)
end
