local create_menu_from_spec = require("configs.nui.lib.menu")
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
  menus[spec.id] = create_menu_from_spec(spec)
end

return menus
