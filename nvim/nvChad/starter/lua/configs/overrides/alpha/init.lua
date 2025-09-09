local alpha_setup = function()
    local present, alpha = pcall(require, "alpha")
    local dashboard = require("alpha.themes.dashboard")

    local base_dashboard = require("configs.overrides.alpha.base")
    local project_dashboard = require("configs.overrides.alpha.project")
    local settings_dashboard = require("configs.overrides.alpha.settings")

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

    local dashboards = {
        default = function()
            return dashboard
        end,
        base = base_dashboard,
        settings = settings_dashboard,
        project = project_dashboard
    }

    local previous_dashboard = "default"

    local function switch_dashboard(new_dashboard)
        if (vim.o.filetype == "alpha") then
            vim.cmd("bd!")
        end
        alpha.setup(new_dashboard(vim.deepcopy(dashboard)).config)
        previous_dashboard = new_dashboard
        vim.cmd("Alpha")
    end

    ucmd("AlphaOmega", function(args)
        local dash_key_to_switch_to = args.args ~= "" and args.args or previous_dashboard
        switch_dashboard(dashboards[dash_key_to_switch_to])
    end, {
        desc = "Opens an Alpha dashboard by key",
        nargs = "?"
    })

    local starter_dashboard = dashboards[previous_dashboard](dashboard)
    alpha.setup(starter_dashboard.config)
end

return alpha_setup
