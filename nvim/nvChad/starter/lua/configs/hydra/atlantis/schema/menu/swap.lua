local M = {}

M.title = " ⇅ Swap"

M.items = {
  { key = "U", icon = "↑", label = "Swap with previous statement", cmd = "SwapUp" },
  { key = "I", icon = "↓", label = "Swap with next statement", cmd = "SwapDown" },
  { key = "W", icon = "←", label = "Swap toward parent node", cmd = "SwapLeft" },
  { key = "A", icon = "→", label = "Swap toward child node", cmd = "SwapRight" },
}

return M
