local treewalker_runner = require("configs.nui.menus.treewalker")

return {
  id = "treewalker_node_action",
  prompt = "Treewalker Node Actions",
  items = {
    { key = "k", icon = "", label = "Swap with previous statement", action = treewalker_runner.run("SwapUp") },
    { key = "j", icon = "", label = "Swap with next statement", action = treewalker_runner.run("SwapDown") },
    { key = "h", icon = "", label = "Swap toward parent node", action = treewalker_runner.run("SwapLeft") },
    { key = "l", icon = "", label = "Swap toward child node", action = treewalker_runner.run("SwapRight") },
  },
}
