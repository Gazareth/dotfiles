local M = {}

function M.run(cmd)
  return function()
    local ok = pcall(require, "treewalker")
    if not ok then
      vim.notify("treewalker.nvim is not available", vim.log.levels.ERROR)
      return
    end

    vim.cmd("Treewalker " .. cmd)
  end
end

return M