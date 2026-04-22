local treesitter_config = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.config")
local atlantis = require("configs.hydra.atlantis")
local namu = require("configs.hydra.hydras.namu")

local M = {}

function M.setup(opts)
  opts = opts or {}
  treesitter_config.setup(opts.treesitter or {})

  vim.keymap.set("n", "<leader>nn", function()
    namu.open()
  end, { desc = "Namu Symbols Menu" })

  vim.keymap.set("n", "<leader>tt", function()
    atlantis.open({ depth = 0 })
  end, { desc = "Atlantis" })

  vim.keymap.set("n", "<leader>tn", function()
    atlantis.open({ depth = 1 })
  end, { desc = "Atlantis (Deep)" })
end

return M
