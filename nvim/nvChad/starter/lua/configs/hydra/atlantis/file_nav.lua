-- File-level landmark Hydra (separate from main Atlantis node menu).
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local file_index = require("configs.hydra.atlantis.anchor.build.file_nav.index")
local file_items = require("configs.hydra.atlantis.anchor.build.file_nav.items")
local make_hydra = require("configs.hydra.lib.make_hydra")
local schema = require("configs.hydra.atlantis.schema.menu.file_nav")

local M = {}

function M.open(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}
  local session = {
    menu_opts = menu_opts,
    hydra_opts = vim.tbl_extend("force", {}, hydra_opts),
  }

  local bufnr = vim.api.nvim_get_current_buf()
  local index = file_index.build(bufnr, schema.kind_order)
  local items = file_items.build(index, menu_opts, session.hydra_opts)

  local spec = {
    title = schema.title,
    sections = {
      { title = schema.section_title, items = items },
    },
    merge_ui_opts = function(_, incoming)
      vim.tbl_extend("force", session.hydra_opts, incoming)
      return session.hydra_opts
    end,
  }

  atlantis_action.wrap_spec_items(spec, session)
  make_hydra(spec, session.hydra_opts):open()
end

return M
