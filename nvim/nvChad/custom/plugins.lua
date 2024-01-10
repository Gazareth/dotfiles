local overrides = require("custom.configs.overrides")
local get_keys = require("custom.functions.lazy").get_keys

local allSurrounds = { "f", "t","[", "]", "{", "}", "(", ")", "\"", "'" }
local allWordMotions = vim.list_extend({ "w", "W", "p", "q", "b" }, allSurrounds)
local allVimCaserKeys = { "m", "p", "c", "_", "u", "U", "t", "s", "<space>", "-", "k", "K", "." }
local allVimUnimpairedKeys = { "a", "A", "b", "B", "l", "L", "<C-L>", "q", "Q", "<C-Q>", "t", "T", "<C-T>", "f", "n", "<space>", "e", "x", "xx", "u", "uu", "y", "yy", "C", "CC"  }

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- override NvChad plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },


  -- Custom plugins
    -- To make a plugin not be loaded
  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   enabled = false
  -- },

  -- All NvChad plugins are lazy-loaded by default
  -- For a plugin to be loaded, you will need to set either `ft`, `cmd`, `keys`, `event`, or set `lazy = false`
  -- If you want a plugin to load on startup, add `lazy = false` to a plugin spec, for example
  -- {
  --   "mg979/vim-visual-multi",
  --   lazy = false,
  -- }

  -- Neovim backend
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
  },

-- Vim motions/controls
  {
    "andymass/vim-matchup",  -- Highlight/move to matching bracket/quote
    keys = { "%", "g%", "[%", "]%", "z%" }
  },

  {
    "arthurxavierx/vim-caser",  -- Commands to re-case selection
    keys = vim.list_extend(
      vim.list_extend(
        get_keys({"n"}, {{"gs"}, {"a", "i"}, allVimCaserKeys, allWordMotions}),
        get_keys({"n"}, {{"gs"}, { "w", "W" }})
      ),
      get_keys({"x"}, {{"gs"}, {"w", "W"}})
    )
  },

  {
    "gbprod/substitute.nvim",  -- Replace selection with default register
    keys = vim.list_extend(
      get_keys({"n"}, {{"s", "ss", "S"}}),
      get_keys({"x"}, {{"s"}})
    ),
    config = function()
      local subst = require("substitute")
      subst.setup()
      vim.keymap.set("n", "s", subst.operator, { desc = "Substitute (With motion)" ,noremap = true })
      vim.keymap.set("n", "ss", subst.line, { desc = "Substitute (Line)" ,noremap = true })
      vim.keymap.set("n", "S", subst.eol, { desc = "Substitute (To end of line)" ,noremap = true })
      vim.keymap.set("x", "s", subst.visual, { desc = "Substitute (Visual selection)" ,noremap = true })
    end
  },

  {
    "tommcdo/vim-exchange",
    keys = vim.list_extend(
      get_keys({"n"}, {{"cx", "cxx", "cxc"}}),
      get_keys({"x"}, {{"X"}})
    )
  },

  { "echasnovski/mini.surround",
    config = function()
      require('mini.surround').setup({
        -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
        highlight_duration = 500,

        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          add = 'ys', -- Add surrounding in Normal and Visual modes
          delete = 'ds', -- Delete surrounding
          find = 'gsf', -- Find surrounding (to the right)
          find_left = 'gsF', -- Find surrounding (to the left)
          highlight = 'gsh', -- Highlight surrounding
          replace = 'cs', -- Replace surrounding
          update_n_lines = '<leader>ysn', -- Update `n_lines`

          suffix_last = 'l', -- Suffix to search with "prev" method
          suffix_next = 'n', -- Suffix to search with "next" method
        },

        -- How to search for surrounding (first inside current line, then inside
        -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
        -- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
        -- see `:h MiniSurround.config`.
        search_method = 'cover_or_nearest',
      })
    end
  },

  -- UI
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
    "lukas-reineke/indent-blankline.nvim",  -- Show indentation levels
    opts = overrides.blankline,
  },

  {
    "mbbill/undotree",  -- Access different undo "timelines"
  },

  -- AutoEditing
  {
    "tpope/vim-unimpaired",  -- bracket pairings
    keys = vim.list_extend(
      vim.list_extend(
        get_keys({"n"}, {{"[", "]"}, allVimUnimpairedKeys}),
        get_keys({"n"}, {{">", "<", "="}, {"p", "P"}})
      ),
      get_keys({"x"}, {{"[", "]"}, { "x", "u", "y", "c" }})
    )
  },

  {
    "AndrewRadev/tagalong.vim",  -- Automatically update matching HTML tag
    ft = { "js", "jsx", "ts", "tsx", "html", "xml" }
  },

  -- Cosmetic
  {
    "echasnovski/mini.cursorword"  -- Highlight all instances of the word under the cursor
  },

  {
    "beauwilliams/focus.nvim",  -- Dynamically resize splits to focus on current one
  },

  {
    "folke/zen-mode.nvim",
      cmd = { "ZenMode" },
      config = function()
        require("zen-mode").setup {
          window = {
            width = .75
          }
        }
      end
  },

  {
    "folke/twilight.nvim",  -- Dim other sections of code
    cmd = { "Twilight", "TwilightEnable", "TwilightDisable" }
  },


  {
    "eandrju/cellular-automaton.nvim",
    cmd = "CellularAutomaton"
  },



}

return plugins
