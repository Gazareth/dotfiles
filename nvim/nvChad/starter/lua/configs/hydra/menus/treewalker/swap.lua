local items = {
  { key = "u", icon = "↑", label = "Swap with previous statement", cmd = "SwapUp" },
  { key = "i", icon = "↓", label = "Swap with next statement", cmd = "SwapDown" },
  { key = "w", icon = "←", label = "Swap toward parent node", cmd = "SwapLeft" },
  { key = "a", icon = "→", label = "Swap toward child node", cmd = "SwapRight" },
}

return {
  title = " ⇅ Swap",
  items = vim.tbl_map(function(item)
    return vim.tbl_extend("force", {
      action = "Treewalker " .. item.cmd,
    }, item)
  end, items),
}
