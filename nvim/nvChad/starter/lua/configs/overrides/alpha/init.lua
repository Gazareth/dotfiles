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

    local dashboard_history = {"base"}

    local function switch_dashboard(new_dashboard_name)
        if (vim.o.filetype == "alpha") then
            vim.cmd("bd!")
        end
        local new_dashboard = dashboards[new_dashboard_name] or dashboards["base"]
        alpha.setup(new_dashboard(vim.deepcopy(dashboard)).config)
        table.insert(dashboard_history, 1, new_dashboard_name)
        vim.cmd("Alpha")
    end

    ucmd("AlphaOmega", function(args)
        if (vim.o.filetype == "alpha") then
            vim.cmd("bd!")
        end
        local dash_key_to_switch_to = args.args ~= "" and args.args or dashboard_history[1]
        local trimmed_key_to_switch_to = dash_key_to_switch_to:match("^%s*(.-)%s*$");
        switch_dashboard(trimmed_key_to_switch_to)
    end, {
        desc = "Opens an Alpha dashboard by key",
        nargs = "?"
    })

    ucmd("AlphaOmegaPrev", function()
        if (vim.o.filetype == "alpha") then
            table.remove(dashboard_history, 1)
            previous_dashboard = dashboard_history[1]
            if previous_dashboard then
                switch_dashboard(previous_dashboard)
            else
                print("No previous dashboard to switch to!")
            end
        else
            local previous_dashboard = dashboard_history[1]
            switch_dashboard(previous_dashboard)
        end
    end, {
        desc = "Opens the previous Alpha dashboard",
        nargs = 0
    })

    local starter_dashboard = dashboards[dashboard_history[1]](dashboard)
    alpha.setup(starter_dashboard.config)
end

return alpha_setup
