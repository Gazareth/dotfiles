local atlantis = require("configs.hydra.atlantis")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")

local menu_opts_nav = { prefer_container = true, depth = 0 }

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

  it("prev sibling jump clears container flags (standard menu)", function()
    helpers.with_lua(nested, 4, helpers.col0(nested[4], "y"), function()
      local v = atlantis.build_view_spec(menu_opts_nav, {})
      local nav = mr.navigate_section(v.spec)
      local item = mr.find_item_by_key(nav.items, "u")
      assert.truthy(item, "expected prev sibling row")
      local captured, restore = mr.stub_atlantis_open()
      item.action(item)
      vim.wait(400, function()
        return #captured > 0
      end)
      restore()
      assert.is_true(#captured >= 1)
      local mo = captured[1].menu_opts
      assert.is_nil(mo.prefer_container)
      assert.is_nil(mo._atlantis_container_session)
    end)
  end)

  it("wrapped reopen keeps container flags when item sets _preserve_container_on_reopen", function()
    local captured, restore = mr.stub_atlantis_open()
    local session = {
      menu_opts = vim.tbl_extend("force", {}, menu_opts_nav),
      hydra_opts = {},
    }
    session.menu_opts.prefer_container = true
    session.menu_opts._atlantis_container_session = true
    local item = {
      _atlantis_reopen_anchor_mode = true,
      _preserve_container_on_reopen = true,
      _reopen_atlantis = 0,
      action = function() end,
    }
    atlantis_action.wrap_item(item, session)
    item.action(item)
    vim.wait(400, function()
      return #captured > 0
    end)
    restore()
    assert.is_true(#captured >= 1)
    local mo = captured[1].menu_opts
    assert.is_true(mo._atlantis_container_session == true or mo.prefer_container == true)
  end)
end)
