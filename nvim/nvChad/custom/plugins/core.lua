-- Neovim core functionality
local M = {
  {
    "nathom/filetype.nvim",  -- Speed up startup time
  },

  {
    "max397574/better-escape.nvim", -- Avoid delays before resolving hotkey chains
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "yuttie/comfortable-motion.vim",  -- Smooth scrolling
    config = function()
      require "custom.configs.comfortable-motion"
    end
  },

  {
    "mg979/vim-visual-multi",  -- Multi cursor
    config = function()
      require "custom.configs.vim-visual-multi"
    end
  },

  {
    "gbprod/stay-in-place.nvim",  -- Prevent cursor moving when searching/filtering
    lazy = false
  },

  {
    "tpope/vim-repeat"  -- Press "." (dot) to repeat last action
  },

  {
    "tomarrell/vim-npr",  -- Follow a file path/url
  },

  {
    "ofirgall/open.nvim",  -- Open a file or Github link
      keys = {"n","gx"},
      config = function()
        require('open').setup {
        }
        vim.keymap.set('n', 'gx', require('open').open_cword)
      end,
  }
}

return M