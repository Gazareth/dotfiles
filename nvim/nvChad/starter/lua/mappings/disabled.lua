---@type MappingsTable
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
      ["<leader>e"] = { "", "focus nvimtree" },
      ["<A-h>"] = { "", "toggle floating term" },
    },
  }

return M
