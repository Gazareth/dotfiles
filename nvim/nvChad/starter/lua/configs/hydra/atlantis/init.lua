local anchor_build = require("configs.hydra.atlantis.anchor.build")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
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
  local anchor_ctx = anchor_build.build(menu_opts)
  local menu_layout = layout.from_context(anchor_ctx)
  local spec = create_hint_menu.create_hint_menu(menu_layout)
  spec.merge_ui_opts = function(_, incoming)
    vim.tbl_extend("force", session.hydra_opts, incoming)
    return session.hydra_opts
  end
  atlantis_action.wrap_spec_items(spec, session)
  make_hydra(spec, session.hydra_opts):open()
end

return M
