local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

M.alpha = require "custom.configs.overrides.alpha"

M.blankline = {
  space_char_blankline = " ",
  show_current_context = true,
  show_current_context_start = true,
  show_first_indent_level = false,
  show_trailing_blankline_indent = false,
  context_char = "┃",
  filetype_exclude = {
    "NvimTree",
    "lspinfo",
    "packer",
    "checkhealth",
    "help",
    "man",
    "alpha",
    "",
  },
  char_highlight_list = blankline_highlight_groups,
  context_highlight_list = blankline_highlight_groups,
}


return M
