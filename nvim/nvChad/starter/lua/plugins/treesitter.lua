local M = {
    {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate" -- Optional: Builds parsers on install/update
    },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- Ensure nvim-treesitter is installed
    after = "nvim-treesitter", -- Install after nvim-treesitter
    config = function()
        local configs = require("nvim-treesitter.configs")
        configs.setup({
            ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html" },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
                ["as"] = "@statement.outer",
                ["is"] = "@statement.inner",
                ["al"] = "@loop.outer",
                ["il"] = "@loop.inner",
                ["ap"] = "@parameter.outer",
                ["ip"] = "@parameter.inner",
                },
            },
            swap = {
                enable = true,
                swap_next = {
                ["<leader>sn"] = "@parameter.inner",
                },
                swap_previous = {
                ["<leader>sp"] = "@parameter.inner",
                },
            },
        })
    end
  },
}

return M