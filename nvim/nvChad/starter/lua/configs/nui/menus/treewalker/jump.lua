local items = {
  { key = "n", icon = "", label = "Jump to parent node", cmd = "Left" },
  { key = "m", icon = "", label = "Jump to previous sibling node", cmd = "Up" },
  { key = "t", icon = "", label = "Jump to next sibling node", cmd = "Down" },
  { key = "y", icon = "", label = "Jump to child node", cmd = "Right" },
}

return vim.tbl_map(function(item)
  return vim.tbl_extend("force", {
    action = "Treewalker " .. item.cmd,
  }, item)
end, items)
