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

vim.lsp.enable(servers)
