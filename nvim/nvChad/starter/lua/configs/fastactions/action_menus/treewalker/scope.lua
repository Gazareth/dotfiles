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
  id = "treewalker_scope",
  prompt = "Treewalker Scope",
  items = {
    { label = "Move: Up", action = run_treewalker("Up") },
    { label = "Move: Down", action = run_treewalker("Down") },
    { label = "Move: Left", action = run_treewalker("Left") },
    { label = "Move: Right", action = run_treewalker("Right") },
  },
}
