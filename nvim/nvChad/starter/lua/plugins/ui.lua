local overrides = require("configs.overrides")

-- UI
local M = {
  {
    "nvim-telescope/telescope-fzf-native.nvim",  -- More efficient telescope search
    build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    lazy = false,
    config = function()
      require("telescope").load_extension "fzf"
    end,
  },

  {
    "nvim-telescope/telescope-ui-select.nvim",  -- Replace neovim's default select UI with telescope
      -- dependencies = "nvim-telescope/telescope.nvim",
      lazy = false,
      config = function()
        require('telescope').load_extension('ui-select')
      end
  },

  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleRefresh", "TroubleClose" },  -- View diagnostic errors in one place
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        vim.keymap.set("n", "gR", function() require("trouble").next({skip_groups = true, jump = true}); end,
          {silent = true, noremap = true}
        ),
      }
    end
  },

  -- IDE
  {
    "AndrewRadev/undoquit.vim",  -- Restore last quit buffer
    cmd = "Undoquit",
    config = function()
      vim.g.undoquit_mapping = ""
      vim.g.undoquit_tab_mapping = ""
    end
  },

  {
    "numToStr/BufOnly.nvim",  -- Close all OTHER buffers
    cmd = "BufOnly"
  },

  {
    "tpope/vim-fugitive",  -- Git actions
    cmd = {
      "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gedit", "Gsplit",
      "Gread", "Gwrite", "Ggrep", "Glgrep", "Gmove",
      "Gdelete", "Gremove", "Gbrowse",
    },
  },

  {
    'goolord/alpha-nvim',  -- Startup dashboard
    lazy = false,
    config = overrides.alpha
  },

  {
    "mbbill/undotree",  -- Access different undo "timelines"
  }
}

return M