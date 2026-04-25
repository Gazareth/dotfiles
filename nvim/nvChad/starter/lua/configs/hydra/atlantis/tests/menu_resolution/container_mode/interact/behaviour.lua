return function()
    describe("outline item reopen", function()
      -- Finds the first actionable (non-separator) item that follows the section heading
      -- matching heading_text. Used to locate "To next <kind>" outline items.
      local function first_item_after_heading(inter, heading_text)
        local in_section = false
        for _, it in ipairs(inter.items or {}) do
          if it.separator and type(it.label) == "string" and it.label:find(heading_text, 1, true) then
            in_section = true
          end
          if in_section and not it.separator and type(it.action) == "function" then
            return it
          end
        end
      end

      it("navigate item for assignment reopens in standard mode", function()
        local lines = { "local lhs = rhs()" }
        helpers.with_lua(lines, 1, helpers.col0(lines[1], "rhs"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local inter = mr.interact_section(v.spec)
          local item = first_item_after_heading(inter, outline_schema.kind_heading[nk.assignment])
          assert.truthy(item, "expected navigate item under Assignments section")
          assert.is_table(item.reopen)
          assert.is_nil(item.reopen.container_scope, "assignment navigate should reopen in standard mode")
        end)
      end)

      it("navigate item for function declaration reopens in container mode", function()
        local lines = {
          "local function outer()",
          "  local function container_fn()",
          "    local function nested()",
          "    end",
          "  end",
          "end",
        }
        helpers.with_lua(lines, 2, helpers.col0(lines[2], "container_fn"), function()
          local v = atlantis.build_view_spec(menu_opts_nav, {})
          local inter = mr.interact_section(v.spec)
          local item = first_item_after_heading(inter, outline_schema.kind_heading[nk.declaration])
          assert.truthy(item, "expected navigate item under Declarations section")
          assert.is_table(item.reopen)
          assert.are.equal("current_scope", item.reopen.container_scope,
            "function declaration navigate should reopen in container mode")
        end)
      end)
    end)
end