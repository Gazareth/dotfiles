local treewalker_runner = require("configs.nui.menus.treewalker")

return {
  id = "treewalker_scope",
  prompt = "Treewalker Scope",
  items = {
    { key = "k", icon = "", label = "Jump to grandparent node", action = treewalker_runner.run("Up") },
    { key = "h", icon = "", label = "Jump to parent node", action = treewalker_runner.run("Left") },
    { key = "j", icon = "", label = "Jump to next sibling node", action = treewalker_runner.run("Down") },
    { key = "l", icon = "", label = "Jump to child node", action = treewalker_runner.run("Right") },
  },
}
