local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local menu_labels = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.labels")
local make_hydra = require("configs.hydra.lib.make_hydra")
local schema = require("configs.hydra.atlantis.schema.menu.outline")
local targets = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.targets")
local title_const = require("configs.hydra.atlantis.menu.components.title.constants")

local M = {}

local KEY_POOL = "1234567890abcdefghijklmnopqrstuvwxyz,./;'-=[]`ABCDEFGHIJKLMNOPQRSTUVWXYZ"

local function alloc_keys(n)
  local used = { q = true, ["?"] = true }
  local keys = {}
  for idx = 1, n do
    local k = nil
    for i = 1, #KEY_POOL do
      local c = KEY_POOL:sub(i, i)
      if not used[c] then
        used[c] = true
        k = c
        break
      end
    end
    keys[#keys + 1] = k or ("+" .. tostring(idx))
  end
  return keys
end

local function picker_row_label(e)
  if type(e) ~= "table" or type(e.node_info) ~= "table" then
    return "[?] ?:-1"
  end
  local kind = type(e.semantic) == "table" and e.semantic.node_kind or nil
  local bracket = title_const.resolve_label(kind, e.node_info.node_type)
  local name = menu_labels.display_name_for_node(e.node_info, e.parsed)
  local line = (type(e.row) == "number" and e.row or 0) + 1
  return string.format("[%s] %s:%d", bracket, name, line)
end

--- @param reopen_args table  explicit reopen args carried by each picker item
function M.open(list, kind_id, reopen_args, hydra_opts)
  reopen_args = type(reopen_args) == "table" and reopen_args or {}
  hydra_opts = vim.tbl_extend("force", {}, type(hydra_opts) == "table" and hydra_opts or {})

  local heading = schema.kind_heading[kind_id]
  if type(heading) ~= "string" or heading == "" then
    heading = tostring(kind_id)
  end

  local keys = alloc_keys(#list)
  local items = {}
  for i, e in ipairs(list) do
    items[#items + 1] = {
      key = keys[i] or ("+" .. tostring(i)),
      icon = "",
      label = picker_row_label(e),
      action = function()
        targets.jump_action(e.node_info)()
      end,
      reopen = reopen_args,
    }
  end

  local spec = {
    title = string.format(" %s %s", schema.picker_title_prefix, heading),
    sections = {
      { title = schema.picker_section_title, items = items },
    },
    merge_ui_opts = function(_, incoming)
      vim.tbl_extend("force", hydra_opts, incoming)
      return hydra_opts
    end,
  }

  atlantis_action.wrap_spec_items(spec, { hydra_opts = hydra_opts })
  make_hydra(spec, hydra_opts):open()
end

return M
