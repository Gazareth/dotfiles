local alpha_config = function()
    local present, alpha = pcall(require, "alpha")

    -- Disable sign column in alpha
    local acmd = vim.api.nvim_create_autocmd
    local agrp = vim.api.nvim_create_augroup
    local ucmd = vim.api.nvim_create_user_command

    -- Turn off tablien when on dashboard
    agrp("alpha_tabline", {
        clear = true
    })

    -- Toggle line numbers off when opening dashboard
    acmd("FileType", {
        group = "alpha_tabline",
        pattern = {"alpha"},
        callback = function()
            vim.schedule(function()
                vim.cmd("set showtabline=0 laststatus=0 noruler nonumber")
            end)
        end
    })

    -- Toggle line numbers on when leaving dashboard
    acmd("FileType", {
        group = "alpha_tabline",
        pattern = {"alpha"},
        callback = function()
            acmd("BufUnload", {
                group = "alpha_tabline",
                buffer = 0,
                callback = function()
                    vim.schedule(function()
                        vim.cmd("set showtabline=2 ruler laststatus=3 number")
                    end)
                end
            })
        end
    })

    -- Don't call alpha.setup! This is done by AlpohaOmega
end

return alpha_config
