local M = {
    {"Shatur/neovim-session-manager",
        dependencies = "nvim-lua/plenary.nvim"
    },
    {
        "coffebar/neovim-project",
        config = function()
          require("neovim-project").setup({
            projects = vim.g.project_patterns,
            last_session_on_startup = false
          })
        end,
        init = function()
          -- enable saving the state of plugins in the session
          vim.opt.sessionoptions:append("globals") -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
        end,
        dependencies = {
          { "nvim-lua/plenary.nvim" },
          { "nvim-telescope/telescope.nvim", tag = "0.1.4" },
          { "Shatur/neovim-session-manager" },
        },
        lazy = true,
        cmd = {
          "NeovimProjectDiscover",
          "NeovimProjectHistory",
          "NeovimProjectLoadRecent",
        },
        priority = 100,
    }
}

return M
