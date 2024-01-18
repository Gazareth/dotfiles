local M = {
    {"ahmedkhalf/project.nvim"},
    {"jedrzejboczar/possession.nvim",
        config = function()
            require("telescope").load_extension "fzf"
        end
    }
}

return M