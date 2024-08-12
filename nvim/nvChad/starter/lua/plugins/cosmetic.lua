-- Cosmetic
local M = {
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
  }
}

return M