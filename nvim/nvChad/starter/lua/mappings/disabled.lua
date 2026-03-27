---@class MappingsTable
local M = {}

M.disabled = {
    t = {
      ["<A-h>"] = { "", "toggle floating term" },
    },
    n = {
      ["<leader>fm"] = { "", "lsp formatting" },
      ["<leader>n"] = { "", "toggle line number" },
      ["<leader>rn"] = { "", "toggle relative number" },
      ["<C-n>"] = { "", "toggle nvimtree" },
      ["<C-c>"] = { "", "general copy whole file" },
      ["<leader>e"] = { "", "focus nvimtree" },
      ["<A-h>"] = { "", "toggle floating term" },
    },
  }

return M
