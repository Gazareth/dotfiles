local h = require("configs.hydra.atlantis-deprecated.tests.helpers")
local targets = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.targets")

--- For scope-isolation unit tests, use the innermost actionable node (chain[1])
--- rather than the resolved anchor. This tests get_siblings_for_node in isolation
--- from the anchor-selection algorithm (which at depth=0 resolves to the enclosing
--- settlement-tier function, not the statement under the cursor).
local function innermost_node(ctx)
  local chain = ctx.candidate_chain or {}
  return (chain[1] and chain[1].node_info) or ctx.anchor_node_info
end

--- Build the sibling list and return the first (trimmed) line of each node's text.
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
  describe("list (unit) -", function()
    it("function body with nested if: two siblings at body level only", function()
      local lines = {
        "local function outer()",
        "  local a = 1",
        "  if true then",
        "    local b = 2",
        "  end",
        "end",
      }
      local sibs = sibling_first_lines(lines, 2, "a")
      assert.are.same(2, #sibs)
      assert.truthy(sibs[1]:find("local a = 1", 1, true))
      assert.truthy(sibs[2]:find("if true then", 1, true))
    end)

    it("if body: only inner statements are siblings, outer scope excluded", function()
      local lines = {
        "local function outer()",
        "  local a = 1",
        "  if true then",
        "    local b = 2",
        "    local c = 3",
        "  end",
        "  local e = 5",
        "end",
      }
      local sibs = sibling_first_lines(lines, 4, "b")
      assert.are.same(2, #sibs)
      assert.truthy(sibs[1]:find("local b = 2", 1, true))
      assert.truthy(sibs[2]:find("local c = 3", 1, true))
    end)

    it("file level: all top-level statements are siblings", function()
      local lines = {
        "local a = 1",
        "local b = 2",
        "local c = 3",
      }
      local sibs = sibling_first_lines(lines, 2, "b")
      assert.are.same(3, #sibs)
      assert.truthy(sibs[1]:find("local a = 1", 1, true))
      assert.truthy(sibs[2]:find("local b = 2", 1, true))
      assert.truthy(sibs[3]:find("local c = 3", 1, true))
    end)

    it("deeply nested: siblings scoped to immediate block, outer locals excluded", function()
      local lines = {
        "local function outer()",
        "  local function inner()",
        "    local x = 1",
        "    local y = 2",
        "  end",
        "  local z = 3",
        "end",
      }
      local sibs = sibling_first_lines(lines, 3, "x")
      assert.are.same(2, #sibs)
      assert.truthy(sibs[1]:find("local x = 1", 1, true))
      assert.truthy(sibs[2]:find("local y = 2", 1, true))
    end)

    it("adjacent functions are siblings, regardless of body content", function()
      local lines = {
        "local function first()",
        "  local a = 1",
        "  local probe_id = semantic_kind and kinds.probe_by_node_kind[semantic_kind] or nil",
        "  if true then",
        "    local b = 2",
        "    local c = 3",
        "  end",
        "  local z = 3",
        "end",
        "local function second()",
        "  local function inner()",
        "    local x = 1",
        "    local y = 2",
        "  end",
        "  local z = 3",
        "end",
      }
      local sibs = sibling_first_lines(lines, 1, "first")
      assert.are.same(2, #sibs)
      assert.truthy(sibs[1]:find("local function first()", 1, true))
      assert.truthy(sibs[2]:find("local function second()", 1, true))
    end)

    it("parameter cursor: individual params are siblings within the parameters container", function()
      local lines = { "local function f(x, y, z) end" }
      local sibs = sibling_first_lines(lines, 1, "z")
      assert.are.same(3, #sibs)
      assert.truthy(sibs[1]:find("^x$"))
      assert.truthy(sibs[2]:find("^y$"))
      assert.truthy(sibs[3]:find("^z$"))
    end)
  end)
end
