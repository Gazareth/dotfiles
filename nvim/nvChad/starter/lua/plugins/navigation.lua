-- Navigation
local M = {
  { "serhez/bento.nvim", opts = {}, event = "DirChanged" },
  {
    "bassamsdata/namu.nvim",
    opts = {
      global = {},
      namu_symbols = { -- Specific Module options
        options = {
          AllowKinds = {
            -- Extend the default lua list
            lua = {
              "Variable", -- For the local assignment at the top
              "Field",    -- For all the nested entries in your table
              "Function",
              "Method",
              "Table",
              "Module",
              "Call",   -- Note: Namu uses "Call" for FunctionCall
              "String", -- If you want to see the raw string values in the list
            },
          },
          BlockList = {
            default = {},
            -- Filetype-specific
            lua = {
              "^vim%.",     -- anonymous functions passed to nvim api
              "%.%.%. :",   -- vim.iter functions
              ":gsub",      -- lua string.gsub
              "^callback$", -- nvim autocmds
              "^filter$",
              "^map$",      -- nvim keymaps
              "^%[%d+%]$",  -- Blocks anonymous fields that look like [1], [20], etc.
            },
            -- another example:
            -- python = { "^__" }, -- ignore __init__ functions
          },
        },
      },
    },
    event = "BufEnter",
  },
}

return M
