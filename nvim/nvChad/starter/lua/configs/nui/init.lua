local M = {}

function M.setup()
  local menus = require("configs.nui.menus")

  menus.namu:bind("n", "<leader>nm", "Namu Fast Menu")
  menus.treewalker_scope:bind("n", "<leader>tws", "Treewalker Scope Menu")
  menus.treewalker_node_action:bind("n", "<leader>twn", "Treewalker Node Actions Menu")

end

return M
