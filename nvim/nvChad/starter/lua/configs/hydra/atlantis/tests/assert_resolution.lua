-- Assertions for standard (non-container) main menu: anchor selection + hint spec.
-- Uses explicit |depth = 0| to match default “standard” selection ([[treesitter]] config).

local anchor_build = require("configs.hydra.atlantis.anchor.build")
local atlantis = require("configs.hydra.atlantis")
local render_spec = require("configs.hydra.atlantis.menu.render_spec")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")

local M = {}

--- Anchor opts for standard-mode resolution (explicit default depth).
M.anchor_opts = { depth = 0 }

--- @param assertions table
--- @field has_anchor_point boolean|nil if false, expect no anchor
--- @field node_kind string|nil expected parsed_anchor.node_kind
--- @field cursor_node_type string|nil expected parsed_anchor.cursor_node_type
--- @field semantic_kind string|nil expected parsed_anchor.semantic_kind (when present)
--- @field specific_section_title string|nil expected Action-column kind subheading (anchor-specific rows)
--- @field has_bespoke_actions boolean|nil if false, expect no anchor-specific actions (no kind subheading)
--- @field sections_include_action_column boolean|nil if true, hint spec must list the action column section
function M.expect_standard_menu(assertions)
  assertions = type(assertions) == "table" and assertions or {}
  local ctx = anchor_build.build(M.anchor_opts)

  if assertions.has_anchor_point == false then
    assert.is_false(ctx.has_anchor_point)
    return
  end

  assert.is_true(ctx.has_anchor_point, "expected anchor at cursor")
  local v = atlantis.build_view_spec({}, {})
  assert.is_false(v.container_mode, "expected standard (non-container) main menu")

  local p = ctx.parsed_anchor
  if assertions.node_kind ~= nil then
    assert.same(assertions.node_kind, p and p.node_kind, "node_kind")
  end
  if assertions.cursor_node_type ~= nil then
    assert.same(assertions.cursor_node_type, p and p.cursor_node_type, "cursor_node_type")
  end
  if assertions.semantic_kind ~= nil then
    assert.same(assertions.semantic_kind, p and p.semantic_kind, "semantic_kind")
  end
  if assertions.has_bespoke_actions == false then
    local rs = render_spec.build(ctx)
    assert.is_nil(rs.specific_section_title, "expected no anchor-specific Action subheading")
  elseif assertions.specific_section_title ~= nil then
    local rs = render_spec.build(ctx)
    assert.same(assertions.specific_section_title, rs.specific_section_title, "specific_section_title")
  end
  if assertions.sections_include_action_column then
    local titles = {}
    for _, sec in ipairs(v.spec.sections or {}) do
      if type(sec) == "table" and type(sec.title) == "string" then
        titles[#titles + 1] = sec.title
      end
    end
    assert.is_true(
      vim.tbl_contains(titles, column_titles.action()),
      "hint sections should include action column title"
    )
  end
end

return M
