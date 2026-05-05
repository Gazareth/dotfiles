local column_titles = require("configs.hydra.atlantis-deprecated.menu.column_titles")

local M = {}

function M.find_section(spec, title)
  for _, sec in ipairs(spec.sections or {}) do
    if type(sec) == "table" and sec.title == title then
      return sec
    end
  end
  return nil
end

function M.navigate_section(spec)
  return M.find_section(spec, column_titles.navigate())
end

function M.interact_section(spec)
  return M.find_section(spec, column_titles.interact())
end

function M.outline_section(spec)
  return M.find_section(spec, column_titles.outline())
end

function M.create_section(spec)
  return M.find_section(spec, column_titles.create())
end

function M.collect_keys(items)
  local keys = {}
  for _, it in ipairs(items or {}) do
    if type(it.key) == "string" and it.key ~= "" then
      keys[it.key] = true
    end
  end
  return keys
end

function M.keys_list(keys_map)
  local out = {}
  for k in pairs(keys_map) do
    out[#out + 1] = k
  end
  table.sort(out)
  return out
end

function M.navigate_schema_key_set()
  local navigate_cfg = require("configs.hydra.atlantis-deprecated.schema.menu").navigate
  local allowed = {}
  for _, row in ipairs(navigate_cfg.items or {}) do
    if type(row.key) == "string" and row.key ~= "" then
      allowed[row.key] = true
    end
  end
  local nh = navigate_cfg.next_highest
  if type(nh) == "table" and type(nh.key) == "string" and nh.key ~= "" then
    allowed[nh.key] = true
  end
  return allowed
end

function M.find_item_by_key(items, key)
  for _, it in ipairs(items or {}) do
    if it.key == key then
      return it
    end
  end
  return nil
end

function M.labels_blob(items)
  local parts = {}
  for _, it in ipairs(items or {}) do
    if type(it.label) == "string" and it.label ~= "" then
      parts[#parts + 1] = it.label
    end
    if type(it.heading) == "string" and it.heading ~= "" then
      parts[#parts + 1] = it.heading
    end
  end
  return table.concat(parts, "\n")
end

function M.stub_atlantis_open()
  local atlantis = require("configs.hydra.atlantis")
  local orig = atlantis.open
  local captured = {}
  atlantis.open = function(menu_opts, hydra_opts)
    captured[#captured + 1] = {
      menu_opts = menu_opts,
      hydra_opts = hydra_opts,
    }
  end
  return captured, function()
    atlantis.open = orig
  end
end

M.jump_schema_key_set = M.navigate_schema_key_set

function M.jump_items_with_key(items)
  local out = {}
  for _, it in ipairs(items or {}) do
    if type(it) == "table" and type(it.key) == "string" and it.key ~= "" then
      out[#out + 1] = it
    end
  end
  return out
end

local menu_actions_schema = require("configs.hydra.atlantis-deprecated.schema.actions.menu")

function M.action_ids_to_labels(render_spec)
  local map = {}
  for _, r in ipairs(render_spec.action_rows or {}) do
    if type(r) == "table" and type(r.action_id) == "string" then
      map[r.action_id] = r.label
    end
  end
  return map
end

function M.expected_menu_label(action_id)
  local spec = menu_actions_schema.action_menu_item[action_id]
  if type(spec) == "table" and type(spec.label) == "string" then
    return spec.label
  end
  return nil
end

function M.quoted_fragment(label)
  if type(label) ~= "string" then
    return nil
  end
  local _, b = label:match('^(.-) %- "(.*)"$')
  if not b then
    return nil
  end
  return b
end

--- Floating hint string: same title + default footer merge as `configs.hydra.lib.make_hydra` before Hydra opens.
function M.build_atlantis_hint_string(spec)
  local hint_mod = require("configs.hydra.lib.hint")
  local hint_opts = vim.tbl_extend("force", {
    title = spec.title,
    footer = {
      left = "[?] toggle hint",
      right = "[q]/[Esc] exit",
    },
  }, type(spec.hint_opts) == "table" and spec.hint_opts or {})
  return hint_mod.build(spec.sections or {}, hint_opts).hint
end

--- Set up a Lua scratch buffer from lines, position cursor at needle on row1, build nav ctx, pass ctx to fn.
--- depth defaults to 0. Pass depth=1 to resolve to the nearest statement/cluster inside a function body.
function M.with_navigate_ctx(lines, row1, needle, fn, depth)
  local h = require("configs.hydra.atlantis-deprecated.tests.helpers")
  local anchor_build = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build")
  h.with_lua(lines, row1, h.col0(lines[row1], needle), function()
    fn(anchor_build.build({ depth = depth or 0 }))
  end)
end

--- if_statement anchor inside a doubly-nested function — cluster tier beats both settlement
--- functions, not an assignment so skip_child=false. Double nesting is required: is_file_scope_anchor
--- returns true for any anchor whose nearest function ancestor is a top-level (root-child) function,
--- so a second function layer is needed to make the inner function non-top-level.
function M.with_all_sections_fixture(fn)
  local lines = {
    "local function outer()",
    "  local function inner()",
    "    if true then",
    "    end",
    "  end",
    "end",
  }
  M.with_navigate_ctx(lines, 3, "if", fn)
end

--- Nested assignment 'b' between 'a' and 'c' — prev and next siblings available.
--- depth=1 is required: depth=0 resolves to the enclosing settlement-tier function, not the statement.
function M.with_nested_sibling_fixture(fn)
  local lines = {
    "local function outer()",
    "  local function inner()",
    "    local a = 1",
    "    local b = 2",
    "    local c = 3",
    "  end",
    "end",
  }
  M.with_navigate_ctx(lines, 4, "b", fn, 1)
end

return M
