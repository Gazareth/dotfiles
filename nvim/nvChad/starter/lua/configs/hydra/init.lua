local Menu = require("configs.hydra.menu")

local M = {}

function M.setup()
  local menus = require("configs.hydra.menus")

  vim.keymap.set("n", "<leader>nn", function()
    Menu.open(menus.namu_all)
  end, { desc = "Namu Symbols Menu" })

  vim.keymap.set("n", "<leader>tt", function()
    Menu.open(menus.treewalker_all)
  end, { desc = "Treewalker Scope & Actions" })
end

return M
