local items = {
  { key = "k", icon = "", label = "Swap with previous statement", cmd = "SwapUp" },
  { key = "j", icon = "", label = "Swap with next statement", cmd = "SwapDown" },
  { key = "h", icon = "", label = "Swap toward parent node", cmd = "SwapLeft" },
  { key = "l", icon = "", label = "Swap toward child node", cmd = "SwapRight" },
}

return vim.tbl_map(function(item)
  return vim.tbl_extend("force", {
    action = "Treewalker " .. item.cmd,
  }, item)
end, items)
