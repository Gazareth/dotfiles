local M = {}

M.treesitter = {
    ensure_installed = {"vim", "lua", "html", "css", "javascript", "typescript", "tsx", "c", "markdown",
                        "markdown_inline"},
    indent = {
        enable = true
        -- disable = {
        --   "python"
        -- },
    }
}

M.mason = {
    ensure_installed = { -- lua stuff
    "lua-language-server", "stylua", -- web dev stuff
    "css-lsp", "html-lsp", "typescript-language-server", "deno", "prettier", -- c/cpp stuff
    "clangd", "clang-format"}
}

-- git support in nvimtree
M.nvimtree = {
    enabled = false,
    git = {
        enable = true
    },

    renderer = {
        highlight_git = true,
        icons = {
            show = {
                git = true
            }
        }
    }
}

M.alpha = require "configs.overrides.alpha"
M.alpha_omega = require "configs.overrides.alpha-omega"

M.blankline = {
    exclude = {
        filetypes = {"NvimTree", "lspinfo", "packer", "checkhealth", "help", "man", "alpha", ""}
    },
    indent = {
        highlight = {"IndentBlanklineIndent1", "IndentBlanklineIndent2", "IndentBlanklineIndent3",
                     "IndentBlanklineIndent4", "IndentBlanklineIndent5", "IndentBlanklineIndent6"}
    }
}

return M
