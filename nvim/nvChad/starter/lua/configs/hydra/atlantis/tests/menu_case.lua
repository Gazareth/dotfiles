-- Helpers for Atlantis open-menu tests: set up a buffer and cursor, then run the shared checks.
--
-- Each case: { test name, lines, row, needle, node_kind, title?, extras? }
--   No title (c[6]) → expect no kind-specific action block.
--   c[6] is a table → treat as extras only (title skipped).
--   extras.has_anchor_point == false → only “no anchor at cursor” (node_kind optional).

local ar = require("configs.hydra.atlantis.tests.assert_resolution")
local helpers = require("configs.hydra.atlantis.tests.helpers")

local M = {}

-- Creates the table of args for expect_standard_menu.
local function merge_expectation(node_kind, section_title, extras)
  -- A table in the title slot means title was skipped; that table is extras.
  if type(section_title) == "table" then
    extras = section_title
    section_title = nil
  end
  extras = type(extras) == "table" and extras or {}
  local expected = vim.tbl_extend("force", {}, extras)
  if expected.has_anchor_point == false then
    return expected
  end
  assert(node_kind ~= nil, "menu_case: node_kind required unless extras.has_anchor_point == false")
  expected.node_kind = node_kind
  if section_title ~= nil then
    expected.specific_section_title = section_title
  else
    expected.has_bespoke_actions = false
  end
  return expected
end

-- Cursor on first `needle` in `lines[row]`. Optional `filetype` + Tree-sitter `lang` (default lua/lua).
function M.expect_at_needle(lines, row, needle, node_kind, section_title, extras, filetype, lang)
  local expected = merge_expectation(node_kind, section_title, extras)
  filetype = filetype or "lua"
  lang = lang or "lua"
  helpers.with_treesitter(lines, filetype, lang, row, helpers.col0(lines[row], needle), function()
    ar.expect_standard_menu(expected)
  end)
end

-- One test per row; passes c[2]..c[7] to expect_at_needle.
function M.run_cases(cases)
  for _, c in ipairs(cases) do
    it(c[1], function()
      M.expect_at_needle(c[2], c[3], c[4], c[5], c[6], c[7])
    end)
  end
end

-- Same as run_cases; uses Tree-sitter. Pending if that parser is missing.
function M.run_treesitter_cases(filetype, lang, cases)
  for _, c in ipairs(cases) do
    it(c[1], function()
      if not helpers.has_parser(lang) then
        pending(lang .. " Tree-sitter parser not available")
        return
      end
      M.expect_at_needle(c[2], c[3], c[4], c[5], c[6], c[7], filetype, lang)
    end)
  end
end

return M
