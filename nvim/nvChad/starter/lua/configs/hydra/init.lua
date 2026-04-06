local Menu = require("configs.hydra.menu")
local treesitter_config = require("configs.hydra.treesitter.config")

local M = {}

-- Keymaps and Tree-sitter setup
function M.setup(opts)
  opts = opts or {}
  treesitter_config.setup(opts.treesitter or {})

  local menus = require("configs.hydra.menus")
  local modes = treesitter_config.get().modes

  vim.keymap.set("n", "<leader>nn", function()
    Menu.open(menus.namu_all)
  end, { desc = "Namu Symbols Menu" })

  vim.keymap.set("n", "<leader>tt", function()
    Menu.open(type(menus.treewalker_all) == "function" and menus.treewalker_all() or menus.treewalker_all)
  end, { desc = "Treewalker Scope & Actions" })

  vim.keymap.set("n", "<leader>tn", function()
    treesitter_config.with_context_mode(modes.max or modes.lowest_node, function()
      Menu.open(type(menus.treewalker_all) == "function" and menus.treewalker_all() or menus.treewalker_all)
    end)
  end, { desc = "Treewalker Max Depth Node" })
end

return M
