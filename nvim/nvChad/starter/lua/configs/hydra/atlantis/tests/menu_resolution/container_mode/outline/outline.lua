local atlantis = require("configs.hydra.atlantis")
local helpers = require("configs.hydra.atlantis.tests.helpers")
local mr = require("configs.hydra.atlantis.tests.menu_resolution.helpers")
local outline_schema = require("configs.hydra.atlantis.schema.menu.outline")
local nk = require("configs.hydra.atlantis.schema.constants").node_kinds

local menu_opts = { container_scope = "current_scope", depth = 0 }

return function()
  describe("Outline -", function()
    local function section_heading(sec, kind_name)
      for _, it in ipairs(sec.items or {}) do
        if it.separator and type(it.label) == "string" and it.label:find(kind_name, 1, true) then
          return it
        end
      end
    end

    -- Fixture: inner() contains only assignments: a, b, c (lines 3-5)
    local three_assignments = {
      "local function outer()",
      "  local function inner()",
      "    local a = 1",
      "    local b = 2",
      "    local c = 3",
      "  end",
      "end",
    }

    -- Fixture: container_fn() contains two nested function declarations
    local two_declarations = {
      "local function outer()",
      "  local function container_fn()",
      "    local function alpha()",
      "    end",
      "    local function beta()",
      "    end",
      "  end",
      "end",
    }

    -- Fixture: mixed() contains one declaration and one assignment
    local mixed_content = {
      "local function outer()",
      "  local function mixed()",
      "    local function nested()",
      "    end",
      "    local x = 1",
      "  end",
      "end",
    }

    describe("assignments section", function()
      it("heading appears when container has assignments", function()
        helpers.with_lua(three_assignments, 2, helpers.col0(three_assignments[2], "inner"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          assert.truthy(sec)
          assert.truthy(
            section_heading(sec, outline_schema.kind_heading[nk.assignment]),
            "expected Assignments section heading"
          )
        end)
      end)

      it("heading includes the item count", function()
        helpers.with_lua(three_assignments, 2, helpers.col0(three_assignments[2], "inner"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local h = section_heading(sec, outline_schema.kind_heading[nk.assignment])
          assert.truthy(h, "expected Assignments heading")
          assert.truthy(h.label:find("[3]", 1, true), "expected count [3] in heading: got " .. tostring(h.label))
        end)
      end)

      it("item label references the variable name", function()
        local single = {
          "local function outer()",
          "  local function inner()",
          "    local myvar = 42",
          "  end",
          "end",
        }
        helpers.with_lua(single, 2, helpers.col0(single[2], "inner"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local blob = mr.labels_blob(sec.items)
          assert.truthy(blob:find("myvar", 1, true), "expected variable name 'myvar' in item labels")
        end)
      end)

      it("navigate item action moves cursor to the assignment", function()
        helpers.with_lua(three_assignments, 2, helpers.col0(three_assignments[2], "inner"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local nav
          for _, it in ipairs(sec.items or {}) do
            if type(it.label) == "string"
              and it.label:find("next", 1, true)
              and it.label:lower():find("assign", 1, true)
              and type(it.action) == "function"
            then
              nav = it
              break
            end
          end
          assert.truthy(nav, "expected a 'To next assignment' navigate item")
          nav.action()
          local row = vim.api.nvim_win_get_cursor(0)[1]
          assert.is_true(row >= 3 and row <= 5, "cursor should land on one of the assignments (lines 3-5)")
        end)
      end)
    end)

    describe("declarations section", function()
      it("heading appears when container has function declarations", function()
        helpers.with_lua(two_declarations, 2, helpers.col0(two_declarations[2], "container_fn"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          assert.truthy(sec)
          assert.truthy(
            section_heading(sec, outline_schema.kind_heading[nk.declaration]),
            "expected Declarations section heading"
          )
        end)
      end)

      it("heading includes the item count", function()
        helpers.with_lua(two_declarations, 2, helpers.col0(two_declarations[2], "container_fn"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local h = section_heading(sec, outline_schema.kind_heading[nk.declaration])
          assert.truthy(h, "expected Declarations heading")
          assert.truthy(h.label:find("[2]", 1, true), "expected count [2] in heading: got " .. tostring(h.label))
        end)
      end)

      it("item label references a function name", function()
        helpers.with_lua(two_declarations, 2, helpers.col0(two_declarations[2], "container_fn"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local blob = mr.labels_blob(sec.items)
          assert.truthy(
            blob:find("alpha", 1, true) or blob:find("beta", 1, true),
            "expected function name in item labels"
          )
        end)
      end)

      it("navigate item action moves cursor to a declaration", function()
        helpers.with_lua(two_declarations, 2, helpers.col0(two_declarations[2], "container_fn"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local nav
          for _, it in ipairs(sec.items or {}) do
            if type(it.label) == "string"
              and it.label:find("next", 1, true)
              and it.label:lower():find("decl", 1, true)
              and type(it.action) == "function"
            then
              nav = it
              break
            end
          end
          assert.truthy(nav, "expected a 'To next declaration' navigate item")
          nav.action()
          local row = vim.api.nvim_win_get_cursor(0)[1]
          assert.is_true(row >= 3 and row <= 7, "cursor should land on alpha or beta (lines 3-7)")
        end)
      end)
    end)

    describe("mixed content", function()
      it("shows both Declarations and Assignments sections", function()
        helpers.with_lua(mixed_content, 2, helpers.col0(mixed_content[2], "mixed"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local blob = mr.labels_blob(sec.items)
          assert.truthy(
            blob:find(outline_schema.kind_heading[nk.declaration], 1, true),
            "expected Declarations section"
          )
          assert.truthy(
            blob:find(outline_schema.kind_heading[nk.assignment], 1, true),
            "expected Assignments section"
          )
        end)
      end)

      it("each section heading count reflects only its own kind", function()
        helpers.with_lua(mixed_content, 2, helpers.col0(mixed_content[2], "mixed"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          local decl_h = section_heading(sec, outline_schema.kind_heading[nk.declaration])
          local asgn_h = section_heading(sec, outline_schema.kind_heading[nk.assignment])
          assert.truthy(decl_h and decl_h.label:find("[1]", 1, true),
            "expected Declarations [1]: got " .. tostring(decl_h and decl_h.label))
          assert.truthy(asgn_h and asgn_h.label:find("[1]", 1, true),
            "expected Assignments [1]: got " .. tostring(asgn_h and asgn_h.label))
        end)
      end)
    end)

    describe("empty container", function()
      local empty_fn = {
        "local function outer()",
        "  local function empty()",
        "  end",
        "end",
      }

      it("does not show Assignments heading when body is empty", function()
        helpers.with_lua(empty_fn, 2, helpers.col0(empty_fn[2], "empty"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          assert.is_falsy(
            section_heading(sec, outline_schema.kind_heading[nk.assignment]),
            "no Assignments section for empty function"
          )
        end)
      end)

      it("does not show Declarations heading when body is empty", function()
        helpers.with_lua(empty_fn, 2, helpers.col0(empty_fn[2], "empty"), function()
          local v = atlantis.build_view_spec(menu_opts, {})
          local sec = mr.outline_section(v.spec)
          assert.is_falsy(
            section_heading(sec, outline_schema.kind_heading[nk.declaration]),
            "no Declarations section for empty function"
          )
        end)
      end)
    end)
  end)
end
