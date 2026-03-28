require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "emmylua_ls" }

vim.lsp.config("emmylua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" } }
    }
  }
})

vim.lsp.enable("lua_ls", false) -- disable lua_ls since we are using emmylua_ls instead
vim.lsp.enable(servers)
