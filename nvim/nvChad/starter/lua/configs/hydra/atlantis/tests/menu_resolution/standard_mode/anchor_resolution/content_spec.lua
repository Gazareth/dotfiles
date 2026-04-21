local helpers = require("configs.hydra.atlantis.tests.helpers")
local supported = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants").supported_nodes
local anchor_build = require("configs.hydra.atlantis.prepare.anchor_point.build")
local anchor_schema = require("configs.hydra.atlantis.schema.actions.anchor")
local render_spec = require("configs.hydra.atlantis.menu.render_spec")

--- Action inventory from the same render pipeline as the Hydra menu (pre-wrap; wrap clears overflow metadata).
local function action_ids_from_anchor_ctx(anchor_ctx)
  local rs = render_spec.build(anchor_ctx)
  local ids = {}
  for _, r in ipairs(rs.action_rows or {}) do
    if type(r) == "table" and type(r.action_id) == "string" then
      ids[r.action_id] = true
    end
  end
  return ids
end

local function assert_enabled_actions_present(node_kind, ids)
  local enabled = anchor_schema.action_names_by_anchor_kind[node_kind]
  assert.truthy(enabled, "schema has kind " .. tostring(node_kind))
  for name, on in pairs(enabled) do
    if on == true then
      assert.truthy(ids[name], "expected action present: " .. name)
    end
  end
end

describe("[Atlantis]", function()
  it("Exposes all enabled actions for function anchor", function()
    local lines = {
      "local function foo()",
      "  return 1",
      "end",
    }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      assert.same(supported.fn, (anchor_ctx.parsed_anchor or {}).node_kind)
      assert_enabled_actions_present(supported.fn, action_ids_from_anchor_ctx(anchor_ctx))
    end)
  end)

  it("Exposes all enabled actions for assignment anchor", function()
    local lines = { "local x = 1" }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      assert.same(supported.assignment, (anchor_ctx.parsed_anchor or {}).node_kind)
      assert_enabled_actions_present(supported.assignment, action_ids_from_anchor_ctx(anchor_ctx))
    end)
  end)

  it("Exposes all enabled actions for identifier identifier", function()
    local lines = { "return x" }
    helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
      local anchor_ctx = anchor_build.build({ depth = 0 })
      if (anchor_ctx.parsed_anchor or {}).node_kind ~= supported.identifier then
        pending("fixture did not resolve to identifier anchor on this parser")
        return
      end
      assert_enabled_actions_present(supported.identifier, action_ids_from_anchor_ctx(anchor_ctx))
    end)
  end)
end)
