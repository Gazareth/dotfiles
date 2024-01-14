local M = {}

M.allSurrounds = { "f", "t","[", "]", "{", "}", "(", ")", "\"", "'" }
M.allWordMotions = vim.list_extend({ "w", "W", "p", "q", "b" }, M.allSurrounds)
M.allVimCaserKeys = { "m", "p", "c", "_", "u", "U", "t", "s", "<space>", "-", "k", "K", "." }
M.allVimUnimpairedKeys = { "a", "A", "b", "B", "l", "L", "<C-L>", "q", "Q", "<C-Q>", "t", "T", "<C-T>", "f", "n", "<space>", "e", "x", "xx", "u", "uu", "y", "yy", "C", "CC"  }

return M