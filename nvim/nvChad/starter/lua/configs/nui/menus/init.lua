local Menu = require("configs.nui.lib.menu")
local namu = require("configs.nui.menus.namu")
local treewalker_scope = require("configs.nui.menus.treewalker.jump")
local treewalker_context = require("configs.nui.menus.treewalker.context")
local treewalker_node_action = require("configs.nui.menus.treewalker.swap")

local menus = {
    namu_all = Menu.create("Namu", {namu.symbols, namu.diagnostics, namu.call_hierarchy}),
    treewalker_all = Menu.create("Treewalker", {treewalker_scope, treewalker_context, treewalker_node_action})
}

return menus
