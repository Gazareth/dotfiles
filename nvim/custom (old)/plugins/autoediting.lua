local keys = require("custom.constants.keys")
local get_keys = require("custom.functions.lazy").get_keys

-- AutoEditing
local M = {
  {
    "tpope/vim-unimpaired",  -- bracket pairings
    keys = vim.list_extend(
      vim.list_extend(
        get_keys({"n"}, {{"[", "]"}, keys.allVimUnimpairedKeys}),
        get_keys({"n"}, {{">", "<", "="}, {"p", "P"}})
      ),
      get_keys({"x"}, {{"[", "]"}, { "x", "u", "y", "c" }})
    )
  },

  {
    "AndrewRadev/tagalong.vim",  -- Automatically update matching HTML tag
    ft = { "js", "jsx", "ts", "tsx", "html", "xml" }
  }
}

return M