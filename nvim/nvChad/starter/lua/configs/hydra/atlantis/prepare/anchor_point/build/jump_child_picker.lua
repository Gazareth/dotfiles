-- Pick a direct named child of the current anchor node to jump to.
local anchor_build = require("configs.hydra.atlantis.prepare.anchor_point.build")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")
local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")
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

local function child_label(child, bufnr)
  local t = child:type()
  local text = vim.trim(node_common.get_node_text(child, bufnr))
  if #text > 40 then
    text = text:sub(1, 37) .. "..."
  end
  if text == "" then
    return t
  end
  return string.format("%s  %s", t, text)
end

--- @param menu_opts table  reopen args from the parent item (carries depth, etc.)
function M.open(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = vim.tbl_extend("force", {}, type(hydra_opts) == "table" and hydra_opts or {})

  local anchor_ctx = anchor_build.build(menu_opts)
  local node_info = anchor_ctx.anchor_node_info
  local node = node_info and node_info.node or nil
  local bufnr = node_info and node_info.bufnr or 0
  if not node then
    return
  end

  local children = node_common.list_named_children(node)
  if #children == 0 then
    vim.notify("No named children to jump to.", vim.log.levels.INFO)
    return
  end

  local reopen_args = { depth = menu_opts.depth or 0 }
  local keys = alloc_keys(#children)
  local items = {}
  for i, child in ipairs(children) do
    local row, col = child:start()
    local target = { bufnr = bufnr, row = row, col = col }
    items[#items + 1] = {
      key = keys[i] or ("+" .. tostring(i)),
      icon = ">",
      label = child_label(child, bufnr),
      action = common_actions.jump_to_target(target),
      reopen = reopen_args,
    }
  end

  local spec = {
    title = " Jump to child",
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
