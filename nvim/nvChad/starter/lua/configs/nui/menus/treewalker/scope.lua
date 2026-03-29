local items = {
  { key = "k", icon = "", label = "Jump to grandparent node", cmd = "Up" },
  { key = "h", icon = "", label = "Jump to parent node", cmd = "Left" },
  { key = "j", icon = "", label = "Jump to next sibling node", cmd = "Down" },
  { key = "l", icon = "", label = "Jump to child node", cmd = "Right" },
}

return vim.tbl_map(function(item)
  return vim.tbl_extend("force", {
    action = "Treewalker " .. item.cmd,
  }, item)
end, items)
