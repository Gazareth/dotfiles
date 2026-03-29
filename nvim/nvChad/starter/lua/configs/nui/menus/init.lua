local Menu = require("configs.nui.lib.menu")
local namu = require("configs.nui.menus.namu")
local treewalker_scope = require("configs.nui.menus.treewalker.scope")
local treewalker_node_action = require("configs.nui.menus.treewalker.node-action")

local menus = {
  namu = Menu.create("Namu", namu),
  treewalker_scope = Menu.create("Treewalker Scope", treewalker_scope),
  treewalker_node_action = Menu.create("Treewalker Node Actions", treewalker_node_action),
}

-- menus.treewalker = setup_menu("Treewalker", {
--   {
--     title = "Scope",
--     items = treewalker_scope,
--   },
--   {
--     title = "Node Actions",
--     items = treewalker_node_action,
--   },
-- })

return menus
