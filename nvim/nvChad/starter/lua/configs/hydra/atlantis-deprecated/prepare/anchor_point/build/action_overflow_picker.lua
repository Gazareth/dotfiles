-- Second-level Hydra for common action overflow ("More common" row).
local anchor_build = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build")
local atlantis_action = require("configs.hydra.atlantis-deprecated.lib.atlantis_action")
local action_labels = require("configs.hydra.atlantis-deprecated.menu.components.action.labels")
local action_rows = require("configs.hydra.atlantis-deprecated.menu.components.action.rows")
local layout = require("configs.hydra.atlantis-deprecated.schema.actions.layout")
local make_hydra = require("configs.hydra.lib.make_hydra")

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

--- @param menu_opts table  reopen args from the parent item (carries depth, etc.)
--- @param action_names string[]
function M.open(menu_opts, hydra_opts, action_names)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = vim.tbl_extend("force", {}, type(hydra_opts) == "table" and hydra_opts or {})
  if type(action_names) ~= "table" or #action_names == 0 then
    return
  end

  local anchor_ctx = anchor_build.build(menu_opts)
  local parsed = anchor_ctx.parsed_anchor
  local node_kind = type(parsed) == "table" and parsed.node_kind or nil
  local node_info = anchor_ctx.anchor_node_info

  local runtime_for_labels = {
    parsed_anchor = parsed,
    anchor_node_info = node_info,
    cursor_node_info = anchor_ctx.cursor_node_info,
    depth = anchor_ctx.depth,
  }
  local row_opts = {
    ctx = {
      node_info = node_info,
      parsed = parsed,
      cursor_node_info = anchor_ctx.cursor_node_info,
      depth = anchor_ctx.depth,
    },
    label_overrides = action_labels.build_overrides(runtime_for_labels),
  }

  local rows = action_rows.build_rows(node_kind, action_names, row_opts)
  if #rows == 0 then
    return
  end

  local keys = alloc_keys(#rows)
  local items = {}
  for i, row in ipairs(rows) do
    local item = vim.tbl_extend("force", {}, row)
    item.key = keys[i] or ("+" .. tostring(i))
    items[#items + 1] = item
  end

  local spec = {
    title = layout.action_overflow_picker_title,
    sections = {
      { title = "", items = items },
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
