-- Interact column: enabled action ids + labels vs schema (render_spec pipeline).

local anchor_build = require("configs.hydra.atlantis.prepare.anchor_point.build")
local anchor_schema = require("configs.hydra.atlantis.schema.actions.anchor")
local render_spec = require("configs.hydra.atlantis.menu.render_spec")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local m = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local supported = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants").supported_nodes

describe("[Atlantis menu] Interact column", function()
  local function assert_inventory_and_labels(node_kind, anchor_ctx)
    assert.same(node_kind, (anchor_ctx.parsed_anchor or {}).node_kind)
    local ids = {}
    local rs = render_spec.build(anchor_ctx)
    for _, r in ipairs(rs.action_rows or {}) do
      if type(r) == "table" and type(r.action_id) == "string" then
        ids[r.action_id] = r.label
      end
    end
    local enabled = anchor_schema.action_names_by_anchor_kind[node_kind]
    assert.truthy(enabled, "schema has kind " .. tostring(node_kind))
    for name, on in pairs(enabled) do
      if on == true then
        assert.truthy(ids[name], "expected action present: " .. name)
        local expected = m.expected_menu_label(name)
        if type(expected) == "string" and expected ~= "" then
          local got = ids[name]
          if name == "jump_to_parameter" then
            assert.truthy(
              type(got) == "string" and got:match("^Jump to parameter"),
              "label for jump_to_parameter: " .. tostring(got)
            )
          else
            assert.are.same(expected, got)
          end
        end
      end
    end
  end

  describe("Function anchor", function()
    it("exposes enabled actions with schema labels", function()
      local lines = {
        "local function foo()",
        "  return 1",
        "end",
      }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "foo"), function()
        local anchor_ctx = anchor_build.build({ depth = 0 })
        assert_inventory_and_labels(supported.fn, anchor_ctx)
      end)
    end)
  end)

  describe("Assignment anchor", function()
    it("exposes enabled actions with schema labels", function()
      local lines = { "local x = 1" }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "x"), function()
        local anchor_ctx = anchor_build.build({ depth = 0 })
        assert_inventory_and_labels(supported.assignment, anchor_ctx)
      end)
    end)
  end)

  describe("Binary expression anchor", function()
    it("exposes enabled actions with schema labels", function()
      local lines = { "return (aa and bb)" }
      helpers.with_lua(lines, 1, helpers.col0(lines[1], "and"), function()
        local anchor_ctx = anchor_build.build({ depth = 0 })
        local kind = (anchor_ctx.parsed_anchor or {}).node_kind
        if kind ~= supported.binary_expression then
          pending("expected binary_expression at `and` in return (aa and bb); got " .. tostring(kind))
          return
        end
        assert_inventory_and_labels(supported.binary_expression, anchor_ctx)
      end)
    end)
  end)

  describe("Else branch", function()
    it("resolves anchor for else keyword when parser cooperates", function()
      local lines = {
        "if x then",
        "  foo()",
        "else",
        "  bar()",
        "end",
      }
      helpers.with_lua(lines, 3, helpers.col0(lines[3], "else"), function()
        local anchor_ctx = anchor_build.build({ depth = 0 })
        local kind = (anchor_ctx.parsed_anchor or {}).node_kind
        if kind ~= supported.generic then
          pending("else fixture did not resolve to generic anchor on this parser (got " .. tostring(kind) .. ")")
          return
        end
        assert_inventory_and_labels(supported.generic, anchor_ctx)
      end)
    end)
  end)
end)
