local parser_path = vim.fn.expand('$LOCALAPPDATA') .. '/nvim-configs/default-data/lazy/nvim-treesitter/parser/lua.so'
if vim.fn.filereadable(parser_path) == 1 then
  vim.treesitter.language.add('lua', { path = parser_path })
else
  error('Lua parser not found: ' .. parser_path)
end
