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
      ["<leader>h"] = { "", "toggle horizontal terminal" },
      ["<C-n>"] = { "", "toggle nvimtree" },
      ["<C-c>"] = { "", "general copy whole file" },
      ["<Esc>"] = { "", "general clear highlights" },
      ["<leader>e"] = { "", "focus nvimtree" },
      ["<A-h>"] = { "", "toggle floating term" },
    },
  }

return M
