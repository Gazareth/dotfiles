local M = {{
    "neovim/nvim-lspconfig",
    config = function()
        require("configs.overrides.lspconfig")
    end
}, {
    "artemave/workspace-diagnostics.nvim",
    opts = {
        debug = true
    }
}, {
    "folke/trouble.nvim",
    enabled = false,
    cmd = {"Trouble", "TroubleToggle", "TroubleRefresh", "TroubleClose"},
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        require("trouble").setup {vim.keymap.set("n", "gR", function()
            require("trouble").next({
                skip_groups = true,
                jump = true
            });
        end, {
            silent = true,
            noremap = true
        })}
    end
}}

return M
