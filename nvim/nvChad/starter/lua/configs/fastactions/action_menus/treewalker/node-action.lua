local function run_treewalker(cmd)
  return function()
    local ok = pcall(require, "treewalker")
    if not ok then
      vim.notify("treewalker.nvim is not available", vim.log.levels.ERROR)
      return
    end

    vim.cmd("Treewalker " .. cmd)
  end
end

return {
  id = "treewalker_node_action",
  prompt = "Treewalker Node Actions",
  items = {
    { label = "Swap: Up", action = run_treewalker("SwapUp") },
    { label = "Swap: Down", action = run_treewalker("SwapDown") },
    { label = "Swap: Left", action = run_treewalker("SwapLeft") },
    { label = "Swap: Right", action = run_treewalker("SwapRight") },
  },
}
