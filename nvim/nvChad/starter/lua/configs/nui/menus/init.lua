local setup_menu = require("configs.nui.lib.menu")
local namu = require("configs.nui.menus.namu")
local treewalker_scope = require("configs.nui.menus.treewalker.scope")
local treewalker_node_action = require("configs.nui.menus.treewalker.node-action")

local specs = {
  namu,
  treewalker_scope,
  treewalker_node_action,
}

local menus = {}
for _, spec in ipairs(specs) do
  menus[spec.id] = setup_menu(spec)
end

return menus
