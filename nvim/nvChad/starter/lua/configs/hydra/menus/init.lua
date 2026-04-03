local namu = require("configs.hydra.menus.namu")
local treewalker_scope = require("configs.hydra.menus.treewalker.jump")
local treewalker_context = require("configs.hydra.menus.treewalker.context")
local treewalker_node_action = require("configs.hydra.menus.treewalker.swap")

return {
  namu_all = {
    title = "Namu",
    sections = { namu.symbols, namu.diagnostics, namu.call_hierarchy },
  },
  treewalker_all = {
    title = "Treewalker",
    sections = { treewalker_scope, treewalker_context, treewalker_node_action },
  },
}
