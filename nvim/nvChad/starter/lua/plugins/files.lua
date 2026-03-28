local M = {
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,      -- Necessary for `default_explorer` to work properly
    opts = require("configs.fyler"),
    keys = {
      { "<C-b>", "<Cmd>Fyler<Cr>", desc = "Open Fyler View" },
    }
  },
  {
    "echasnovski/mini.files",
    enabled = false,
    -- From https://www.reddit.com/r/neovim/comments/1bceiw2/comment/kuhmdp9/
    config = require("configs.mini-files"),
    lazy = true,
    cmd = { "MiniFilesOpen" },
  }
}

return M
