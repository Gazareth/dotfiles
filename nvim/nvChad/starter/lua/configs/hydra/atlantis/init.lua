local anchor_build = require("configs.hydra.atlantis.anchor.build")
local reopen_seed = require("configs.hydra.atlantis.anchor.build.reopen_seed")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local position_cursor = require("configs.hydra.atlantis.lib.position_cursor")
local create_hint_menu = require("configs.hydra.atlantis.menu.create_hint_menu")
local layout = require("configs.hydra.atlantis.menu.layout")
local make_hydra = require("configs.hydra.lib.make_hydra")

local M = {}

M.file_nav = require("configs.hydra.atlantis.file_nav")

function M.open(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}
  local session = {
    menu_opts = menu_opts,
    hydra_opts = vim.tbl_extend("force", {}, hydra_opts),
  }

  if menu_opts._atlantis_reopen_snap then
    menu_opts._atlantis_reopen_snap = nil
    reopen_seed.apply(menu_opts._atlantis_anchor_seed)
  end

  local anchor_ctx = anchor_build.build(menu_opts)
  local menu_layout = layout.from_context(anchor_ctx)
  local spec = create_hint_menu.create_hint_menu(menu_layout)
  local hotkey_pool = type(menu_opts.hotkey_pool) == "string" and menu_opts.hotkey_pool
    or type(hydra_opts.hotkey_pool) == "string" and hydra_opts.hotkey_pool
    or nil
  if hotkey_pool ~= nil then
    spec.hint_opts = vim.tbl_extend("force", type(spec.hint_opts) == "table" and spec.hint_opts or {}, {
      hotkey_pool = hotkey_pool,
    })
  end
  spec.merge_ui_opts = function(_, incoming)
    vim.tbl_extend("force", session.hydra_opts, incoming)
    return session.hydra_opts
  end
  atlantis_action.wrap_spec_items(spec, session)
  if anchor_ctx.anchor_node_info and anchor_ctx.anchor_node_info.node then
    menu_opts._atlantis_anchor_seed = reopen_seed.pack(anchor_ctx.anchor_node_info)
  else
    menu_opts._atlantis_anchor_seed = nil
  end

  if spec.anchor_node_info then
    position_cursor.at_node_info(spec.anchor_node_info)
    spec.anchor_node_info = nil
  end

  make_hydra(spec, session.hydra_opts):open()
end

return M
