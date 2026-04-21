-- _reopen_atlantis depth: wrapped actions preserve menu depth (+1).

local anchor_build = require("configs.hydra.atlantis.anchor.build")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local render_spec = require("configs.hydra.atlantis.menu.render_spec")
local helpers = require("configs.hydra.atlantis.tests.helpers")

describe("[Atlantis menu] Interact column - reopen depth", function()
  local function stub_open_capture()
    local atlantis = require("configs.hydra.atlantis")
    local orig = atlantis.open
    local captured = {}
    atlantis.open = function(menu_opts, hydra_opts)
      captured[#captured + 1] = {
        depth = menu_opts and menu_opts.depth,
        hydra_opts = hydra_opts,
      }
    end
    return captured, function()
      atlantis.open = orig
    end
  end

  it("jump_to_body schedules reopen at depth + 1", function()
    local lines = {
      "local function foo()",
      "  local x = 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local rs = render_spec.build(anchor_ctx)
      local row
      for _, r in ipairs(rs.action_rows or {}) do
        if r.action_id == "jump_to_body" then
          row = r
          break
        end
      end
      assert.truthy(row)
      local item = vim.deepcopy(row)
      local captured, restore = stub_open_capture()
      local session = { menu_opts = { depth = 0 }, hydra_opts = {} }
      atlantis_action.wrap_item(item, session)
      item.action(item)
      vim.wait(300, function()
        return #captured > 0
      end)
      restore()
      assert.is_true(#captured >= 1)
      assert.are.same(1, captured[1].depth)
    end)
  end)

  it("jump_to_parameter schedules reopen at depth + 1", function()
    local lines = {
      "local function foo(a)",
      "  return a",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      local rs = render_spec.build(anchor_ctx)
      local row
      for _, r in ipairs(rs.action_rows or {}) do
        if r.action_id == "jump_to_parameter" then
          row = r
          break
        end
      end
      assert.truthy(row)
      local item = vim.deepcopy(row)
      local captured, restore = stub_open_capture()
      local session = { menu_opts = { depth = 0 }, hydra_opts = {} }
      atlantis_action.wrap_item(item, session)
      item.action(item)
      vim.wait(300, function()
        return #captured > 0
      end)
      restore()
      assert.is_true(#captured >= 1)
      assert.are.same(1, captured[1].depth)
    end)
  end)
end)
