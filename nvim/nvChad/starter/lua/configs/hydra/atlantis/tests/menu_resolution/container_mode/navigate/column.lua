local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

local menu_opts_nav = { container_scope = "current_scope", depth = 0 }

return function()
  describe("Column", function()
    it("exposes only keys from navigate schema (nested scope)", function()
      local nested = {
        "local function outer()",
        "  local function inner(a, b)",
        "    local x = 1",
        "    local y = 2",
        "    return x",
        "  end",
        "end",
      }
      helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
        local v = atlantis.build_view_spec(menu_opts_nav, {})
        assert.is_true(v.container_mode)
        local nav = mr.navigate_section(v.spec)
        local have = mr.collect_keys(nav.items)
        local allowed = mr.navigate_schema_key_set()
        for k in pairs(have) do
          assert.is_true(allowed[k], "unexpected navigate key: " .. tostring(k))
        end
        assert.is_true(have["H"] or have["h"], "expected context navigation keys")
        assert.is_true(have["u"] or have["i"], "expected sibling keys when siblings exist")
      end)
    end)
  end)
end
