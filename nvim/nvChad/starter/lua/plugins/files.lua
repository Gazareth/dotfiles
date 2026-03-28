local fyler_config = require("configs.fyler")

local M = {
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    branch = "stable",
    lazy = false,      -- Necessary for `default_explorer` to work properly
    opts = fyler_config.opts,
    keys = fyler_config.keys,
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
