local Menu = require("configs.nui.lib.menu")
local namu = require("configs.nui.menus.namu")
local treewalker_scope = require("configs.nui.menus.treewalker.jump")
local treewalker_node_action = require("configs.nui.menus.treewalker.swap")

local menus = {
    namu = Menu.create("Namu", {namu}),
    treewalker_scope = Menu.create("Treewalker Scope", {treewalker_scope}),
    treewalker_node_action = Menu.create("Treewalker Node Actions", {treewalker_node_action}),
    treewalker_split = Menu.create("Treewalker", {treewalker_scope, treewalker_node_action})
}

return menus
