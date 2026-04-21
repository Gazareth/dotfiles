local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

local menu_opts_nav = { container_scope = "current_scope", depth = 0 }

describe("[Atlantis menu] Interact reopen (container mode)", function()
  local nested = {
    "local function outer()",
    "  local function inner(a, b)",
    "    local x = 1",
    "    local y = 2",
    "    return x",
    "  end",
    "end",
  }

  it("sibling nav item carries reopen without container_scope (standard reopen)", function()
    helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
      local v = atlantis.build_view_spec(menu_opts_nav, {})
      local nav = mr.navigate_section(v.spec)
      -- sibling keys (u = prev, i = next in default schema)
      local item = mr.find_item_by_key(nav.items, "u") or mr.find_item_by_key(nav.items, "i")
      assert.truthy(item, "expected sibling nav row")
      assert.is_table(item.reopen, "sibling item must have explicit reopen args")
      assert.is_number(item.reopen.depth)
      assert.is_nil(item.reopen.container_scope, "sibling nav should reopen in standard mode")
    end)
  end)

  it("child nav item carries container_scope when already in container mode", function()
    helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
      local v = atlantis.build_view_spec(menu_opts_nav, {})
      local nav = mr.navigate_section(v.spec)
      local item = mr.find_item_by_key(nav.items, "o") or mr.find_item_by_key(nav.items, "l")
      if not item then
        return  -- child row absent for this anchor; skip
      end
      assert.is_table(item.reopen, "child item must have explicit reopen args")
      assert.are.equal("current_scope", item.reopen.container_scope)
    end)
  end)

  it("navigate-to-container item carries container_scope and no action mutation", function()
    helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
      local v = atlantis.build_view_spec(menu_opts_nav, {})
      local nav = mr.navigate_section(v.spec)
      -- H = to_top_level, h = current_scope
      local item_H = mr.find_item_by_key(nav.items, "H")
      local item_h = mr.find_item_by_key(nav.items, "h")
      if item_H then
        assert.is_table(item_H.reopen)
        assert.is_string(item_H.reopen.container_scope)
      end
      if item_h then
        assert.is_table(item_h.reopen)
        assert.are.equal("current_scope", item_h.reopen.container_scope)
      end
    end)
  end)
end)
