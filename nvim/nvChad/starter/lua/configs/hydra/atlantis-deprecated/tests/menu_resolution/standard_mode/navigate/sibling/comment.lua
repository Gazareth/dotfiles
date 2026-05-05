local h = require("configs.hydra.atlantis-deprecated.tests.helpers")
local m = require("configs.hydra.atlantis-deprecated.tests.menu_resolution.helpers")
local targets = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.targets")

local function innermost_node(ctx)
  local chain = ctx.candidate_chain or {}
  return (chain[1] and chain[1].node_info) or ctx.anchor_node_info
end

local function sibling_first_lines(lines, row1, needle)
  local result = {}
  h.with_lua(lines, row1, h.col0(lines[row1], needle), function(bufnr)
    local anchor_build = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build")
    local ctx = anchor_build.build({ depth = 0 })
    local sc = innermost_node(ctx)
    if not sc then return end
    for _, node in ipairs(targets.get_siblings_for_node(sc)) do
      local text = vim.treesitter.get_node_text(node, bufnr)
      result[#result + 1] = (text:match("^([^\n]+)") or text):gsub("^%s+", "")
    end
  end)
  return result
end

return function()
  describe("Comment skipping -", function()
    it("comment nodes are absent from the sibling list", function()
      local lines = {
        "-- docs",
        "local a = 1",
        "local b = 2",
      }
      local sibs = sibling_first_lines(lines, 3, "b")
      assert.are.same(2, #sibs)
      assert.truthy(sibs[1]:find("local a = 1", 1, true))
      assert.truthy(sibs[2]:find("local b = 2", 1, true))
    end)

    it("comment between statements is excluded from the sibling list", function()
      local lines = {
        "local a = 1",
        "-- separator",
        "local b = 2",
        "local c = 3",
      }
      local sibs = sibling_first_lines(lines, 4, "c")
      assert.are.same(3, #sibs)
      assert.truthy(sibs[1]:find("local a = 1", 1, true))
      assert.truthy(sibs[2]:find("local b = 2", 1, true))
      assert.truthy(sibs[3]:find("local c = 3", 1, true))
    end)

    it("next sibling navigation skips over a comment to reach the following statement", function()
      local lines = {
        "local a = 1",
        "-- separator",
        "local b = 2",
      }
      m.with_navigate_ctx(lines, 1, "a", function(ctx)
        local next_item = m.find_item_by_key(ctx.nav_column_spec.items, "i")
        assert.truthy(next_item, "expected next-sibling item on key i")
        next_item.action()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        assert.are.same(3, row, "next sibling should be b on row 3, not the comment on row 2")
      end)
    end)

    it("multiple consecutive comments before a statement are all excluded", function()
      local lines = {
        "-- line 1",
        "-- line 2",
        "-- line 3",
        "local a = 1",
        "local b = 2",
      }
      local sibs = sibling_first_lines(lines, 5, "b")
      assert.are.same(2, #sibs)
      assert.truthy(sibs[1]:find("local a = 1", 1, true))
      assert.truthy(sibs[2]:find("local b = 2", 1, true))
    end)
  end)
end
