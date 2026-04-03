local overrides = require("configs.overrides")

-- UI
local M = { {
  "nvim-telescope/telescope-fzf-native.nvim",
  build =
  "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
  lazy = false,
  config = function()
    require("telescope").load_extension "fzf"
  end
}, {
  "nvim-telescope/telescope-ui-select.nvim",
  -- dependencies = "nvim-telescope/telescope.nvim",
  lazy = false,
  config = function()
    require('telescope').load_extension('ui-select')
  end
},
  {
    "anuvyklack/hydra.nvim",
    event = "VeryLazy",
    config = function()
      require("configs.hydra").setup()
    end,
  },
  -- Restore last quit buffer
  {
    "AndrewRadev/undoquit.vim",
    cmd = "Undoquit",
    config = function()
      vim.g.undoquit_mapping = ""
      vim.g.undoquit_tab_mapping = ""
    end
  },

  -- Close all OTHER buffers
  {
    "numToStr/BufOnly.nvim",
    cmd = "BufOnly"
  },
  {
    "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gedit", "Gsplit", "Gread", "Gwrite", "Ggrep", "Glgrep", "Gmove",
      "Gdelete", "Gremove", "Gbrowse" }
  },
  {
    'goolord/alpha-nvim',
    lazy = false,
    config = overrides.alpha
  },
  {
    'Gazareth/alpha-omega-nvim',
    lazy = false,
    config = overrides.alpha_omega
  },
  { "mbbill/undotree" } -- Access different undo "timelines"
}

return M
