local namu = require("configs.hydra.hydras.namu")

local M = {}

function M.setup(opts)
  opts = opts or {}

  vim.keymap.set("n", "<leader>nn", function()
    namu.open()
  end, { desc = "Namu Symbols Menu" })

  vim.keymap.set("n", "<leader>h", function()
    vim.cmd("AtlantisNouveau")
  end, { desc = "Atlantis" })
end

return M
