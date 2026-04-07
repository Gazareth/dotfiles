local Menu = require("configs.hydra.common.menu")
local treesitter_config = require("configs.hydra.atlantis.treesitter.config")
local atlantis = require("configs.hydra.atlantis")
local namu = require("configs.hydra.namu")

local M = {}

-- Keymaps and Tree-sitter setup
function M.setup(opts)
  opts = opts or {}
  treesitter_config.setup(opts.treesitter or {})

  local modes = treesitter_config.get().modes

  vim.keymap.set("n", "<leader>nn", function()
    Menu.open({
      title = "Namu",
      sections = { namu.symbols, namu.diagnostics, namu.call_hierarchy },
    })
  end, { desc = "Namu Symbols Menu" })

  vim.keymap.set("n", "<leader>tt", function()
    Menu.open(atlantis.build_menu_spec())
  end, { desc = "Treewalker Scope & Actions" })

  vim.keymap.set("n", "<leader>tn", function()
    treesitter_config.with_context_mode(modes.max or modes.lowest_node, function()
      Menu.open(atlantis.build_menu_spec())
    end)
  end, { desc = "Treewalker Max Depth Node" })
end

return M
