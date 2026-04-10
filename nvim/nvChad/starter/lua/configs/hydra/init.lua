local Menu = require("configs.hydra.common.menu")
local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")
local atlantis_layout = require("configs.hydra.atlantis.menu.layout")
local namu = require("configs.hydra.namu")

local M = {}

-- Keymaps and Tree-sitter setup
function M.setup(opts)
  opts = opts or {}
  treesitter_config.setup(opts.treesitter or {})

  vim.keymap.set("n", "<leader>nn", function()
    Menu.open({
      title = "Namu",
      sections = { namu.symbols, namu.diagnostics, namu.call_hierarchy },
    })
  end, { desc = "Namu Symbols Menu" })

  vim.keymap.set("n", "<leader>tt", function()
    Menu.open(atlantis_layout.build_menu_spec({
      depth = 0,
    }))
  end, { desc = "Treewalker Scope & Actions" })

  vim.keymap.set("n", "<leader>tn", function()
    Menu.open(atlantis_layout.build_menu_spec({
      depth = 1,
    }))
  end, { desc = "Treewalker Max Depth Node" })
end

return M
