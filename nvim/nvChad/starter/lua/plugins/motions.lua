local keys = require("constants.keys")
local get_keys = require("functions.lazy").get_keys

-- Vim motions/controls
local M = {
  {
    "andymass/vim-matchup",  -- Highlight/move to matching bracket/quote
    keys = { "%", "g%", "[%", "]%", "z%" }
  },

  {
    "arthurxavierx/vim-caser",  -- Commands to re-case selection
    keys = vim.list_extend(
      vim.list_extend(
        get_keys({"n"}, {{"gs"}, {"a", "i"}, keys.allVimCaserKeys, keys.allWordMotions}),
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
  }
}

return M