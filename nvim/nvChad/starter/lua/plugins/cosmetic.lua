local overrides = require("configs.overrides")

-- Cosmetic
local M = {
  {
    "echasnovski/mini.cursorword",  -- Highlight all instances of the word under the cursor
    event = "BufEnter ",
    version = false,
    config = function()
      require('mini.cursorword').setup()
    end
  },

  {
    "lukas-reineke/indent-blankline.nvim",  -- Show indentation levels
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = overrides.blankline,
  },

 {
    "beauwilliams/focus.nvim",  -- Dynamically resize splits to focus on current one
    version = false,
    lazy = false,
    config = function() require("focus").setup() end
 },

{
  "rlychrisg/truncateline.nvim", -- Hints at offscreen text when horizontally scrolling
  enabled = false
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
 }
}

return M
