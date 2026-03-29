local namu = require("configs.fastactions.action_menus.namu")
local treewalker_scope = require("configs.fastactions.action_menus.treewalker.scope")
local treewalker_node_action = require("configs.fastactions.action_menus.treewalker.node-action")

return {
  menus = {
    [namu.id] = namu,
    [treewalker_scope.id] = treewalker_scope,
    [treewalker_node_action.id] = treewalker_node_action,
  },
  keymaps = {
    { mode = "n", lhs = "<leader>nm", menu = "namu", desc = "Namu Fast Menu" },
    { mode = "n", lhs = "<leader>ew", rhs = "<cmd>Namu symbols<CR>", desc = "Namu - LSP Symbols" },
    { mode = "n", lhs = "<leader>sw", rhs = "<cmd>Namu workspace<CR>", desc = "Namu - Workspace LSP Symbols" },
    { mode = "n", lhs = "<leader>tws", menu = "treewalker_scope", desc = "Treewalker Scope Menu" },
    { mode = "n", lhs = "<leader>twn", menu = "treewalker_node_action", desc = "Treewalker Node Actions Menu" },
  },
}
