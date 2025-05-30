local keys = require("constants.keys")
local get_keys = require("functions.lazy").get_keys

-- AutoEditing
local M = {
  -- {
  --   "tpope/vim-unimpaired",  -- bracket pairings
  --   keys = vim.list_extend(
  --     vim.list_extend(
  --       get_keys({"n"}, {{"[", "]"}, keys.allVimUnimpairedKeys}),
  --       get_keys({"n"}, {{">", "<", "="}, {"p", "P"}})
  --     ),
  --     get_keys({"x"}, {{"[", "]"}, { "x", "u", "y", "c" }})
  --   )
  -- },

  -- {
  --   "AndrewRadev/tagalong.vim",  -- Automatically update matching HTML tag
  --   ft = { "js", "jsx", "ts", "tsx", "html", "xml" }
  -- },

  {
    "stevearc/conform.nvim", -- formatter
    -- event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },

{
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = true,
    cmd = {
      "Refactor"
    },
    opts = {},
  },
}

return M