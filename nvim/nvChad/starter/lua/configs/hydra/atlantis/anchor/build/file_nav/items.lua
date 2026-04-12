local index_mod = require("configs.hydra.atlantis.anchor.build.file_nav.index")
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local schema = require("configs.hydra.atlantis.schema.menu.file_nav")
local title_const = require("configs.hydra.atlantis.menu.components.title.constants")
local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")

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

local function row_jump_quoted(e)
  if type(e) ~= "table" or type(e.node_info) ~= "table" then
    return '"?"'
  end
  local q = menu_labels.quoted_for_node(e.node_info, e.parsed)
  if type(q) == "string" and q ~= "" then
    return q
  end
  return '"?"'
end

local function fmt_entry(e)
  return string.format("%s:%d", row_jump_quoted(e), e.row + 1)
end

local function label_to_quoted_target(quoted)
  return string.format("%s %s", schema.text.to, quoted)
end

local function reopen_atlantis(menu_opts, hydra_opts)
  require("configs.hydra.atlantis").open(menu_opts or {}, hydra_opts or {})
end

local function append_section_heading(items, heading)
  if type(heading) ~= "string" or heading == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = heading }
  items[#items + 1] = { separator = true }
end

--- Icon (same as Treewalker title badges) + "Name [n]" for the separator subtitle.
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

local function kind_pick_heading(kind_id)
  local title = schema.kind_heading[kind_id]
  if type(title) == "string" and title ~= "" then
    return string.format("To %s...", title)
  end
  return "To ..."
end

--- @param opts { next_key: string, pick_key: string, section_heading: string, pick_heading: string }
local function append_category(items, list, row0, col0, menu_opts, hydra_opts, opts)
  local n = #list
  if n == 0 then
    return
  end

  append_section_heading(items, opts.section_heading)

  local pick_heading = opts.pick_heading
  if type(pick_heading) ~= "string" or pick_heading == "" then
    pick_heading = "To ..."
  end

  if n == 1 then
    local e = list[1]
    items[#items + 1] = {
      key = opts.next_key,
      icon = "",
      label = label_to_quoted_target(row_jump_quoted(e)),
      action = function()
        targets.jump_action(e.node_info)()
      end,
      _reopen_atlantis = 0,
    }
    return
  end

  local ni = index_mod.next_index(list, row0, col0)
  local e = ni and list[ni]
  items[#items + 1] = {
    key = opts.next_key,
    icon = "",
    label = e and label_to_quoted_target(row_jump_quoted(e)) or (schema.text.to .. " ..."),
    action = function()
      if not e then
        return
      end
      targets.jump_action(e.node_info)()
    end,
    _reopen_atlantis = 0,
  }
  items[#items + 1] = {
    key = opts.pick_key,
    icon = "",
    label = pick_heading,
    action = function()
      vim.ui.select(list, {
        prompt = pick_heading,
        format_item = fmt_entry,
      }, function(choice)
        if type(choice) ~= "table" then
          return
        end
        vim.schedule(function()
          targets.jump_action(choice.node_info)()
          reopen_atlantis(menu_opts, hydra_opts)
        end)
      end)
    end,
    _reopen_atlantis = -1,
  }
end

--- @param index table from index_mod.build
function M.build(index, menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}
  local items = {}
  local row0, col0 = index_mod.cursor_pos0()

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
        append_category(items, list, row0, col0, menu_opts, hydra_opts, {
          next_key = keys[1],
          pick_key = keys[2],
          section_heading = kind_section_heading(kind_id, n),
          pick_heading = kind_pick_heading(kind_id),
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
