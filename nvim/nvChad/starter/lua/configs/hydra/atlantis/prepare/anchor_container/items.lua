local index_mod = require("configs.hydra.atlantis.prepare.anchor_container.index")
local item_labels = require("configs.hydra.atlantis.prepare.anchor_container.item_labels")
local picker_hydra = require("configs.hydra.atlantis.prepare.anchor_container.picker")
local schema = require("configs.hydra.atlantis.schema.menu.outline")
local title_const = require("configs.hydra.atlantis.menu.components.title.constants")
local targets = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.targets")
local node_kinds = require("configs.hydra.atlantis.schema.constants").node_kinds



local M = {}

local SECTION_KEY_PAIRS = {
  { "c", "v" },
  { "f", "g" },
  { "n", "m" },
  { "t", "r" },
  { "d", "s" },
  { "x", "z" },
  { "e", "w" },
  { "a", "b" },
  { "p", "k" },
}

local function append_section_heading(items, heading)
  if type(heading) ~= "string" or heading == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = heading }
  items[#items + 1] = { separator = true }
end

local function kind_section_heading(kind_id, count)
  local icon = title_const.resolve_icon(kind_id, nil)
  if type(icon) ~= "string" then
    icon = ""
  end
  local title = schema.kind_heading[kind_id]
  if type(title) ~= "string" or title == "" then
    title = tostring(kind_id)
  end
  local core = string.format("%s [%d]", title, count)
  if icon ~= "" then
    return string.format(" %s %s", icon, core)
  end
  return " " .. core
end

local function append_category(items, list, row0, col0, reopen_args, hydra_opts, opts)
  local n = #list
  if n == 0 then
    return
  end

  append_section_heading(items, opts.section_heading)

  if n == 1 then
    local e = list[1]
    items[#items + 1] = {
      key = opts.next_key,
      icon = "",
      label = item_labels.row_single(e),
      action = function()
        targets.jump_action(e.node_info)()
      end,
      reopen = reopen_args,
    }
    return
  end

  local ni = index_mod.next_index(list, row0, col0)
  local e = ni and list[ni]
  items[#items + 1] = {
    key = opts.next_key,
    icon = "",
    label = e and item_labels.row_next(e) or (schema.text.to_next .. " ..."),
    action = function()
      if not e then
        return
      end
      targets.jump_action(e.node_info)()
    end,
    reopen = reopen_args,
  }
  items[#items + 1] = {
    key = opts.pick_key,
    icon = "",
    label = item_labels.pick_row(opts.kind_id),
    action = function()
      picker_hydra.open(list, opts.kind_id, reopen_args, hydra_opts)
    end,
  }
end

function M.build(index, menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}
  local items = {}
  local row0, col0 = index_mod.cursor_pos0()

  local base_depth = menu_opts.depth or 0

  local function reopen_for_kind(kind_id)
    return { depth = base_depth }
  end

  local by_kind = type(index) == "table" and index.by_kind or {}
  local kind_order = type(index) == "table" and index.kind_order or schema.kind_order
  local pair_i = 0

  local function append_kind_sections(order)
    for _, kind_id in ipairs(order) do
      local list = by_kind[kind_id]
      if type(list) == "table" and #list > 0 then
        pair_i = pair_i + 1
        local keys = SECTION_KEY_PAIRS[pair_i] or { "1", "2" }
        local n = #list
        append_category(items, list, row0, col0, reopen_for_kind(kind_id), hydra_opts, {
          next_key = keys[1],
          pick_key = keys[2],
          section_heading = kind_section_heading(kind_id, n),
          kind_id = kind_id,
        })
      end
    end
  end

  append_kind_sections(kind_order)

  local seen = {}
  for _, kid in ipairs(kind_order) do
    seen[kid] = true
  end
  local orphan_kinds = {}
  for kid, list in pairs(by_kind) do
    if not seen[kid] and type(list) == "table" and #list > 0 then
      orphan_kinds[#orphan_kinds + 1] = kid
    end
  end
  table.sort(orphan_kinds)
  append_kind_sections(orphan_kinds)

  if #items == 0 then
    items[#items + 1] = {
      separator = true,
    }
    items[#items + 1] = {
      separator = true,
      label = " No actionable nodes ",
    }
    items[#items + 1] = {
      separator = true,
    }
  end

  return items
end

return M
