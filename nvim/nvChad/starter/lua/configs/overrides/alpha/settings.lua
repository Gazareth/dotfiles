local settings_alpha_setup = function()
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val =
        {"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀⠀⠀⣠⣷⣦⣄⠀⠀⠀⠀⠀⠀⠀",
         "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣶⣤⣤⣶⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀",
         "⠀⠀⠀⣠⣶⣤⣀⣀⣠⣼⣿⠿⠛⠋⠉⠉⠙⠛⠿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀",
         "⠀⠀⣰⣿⣿⣿⣿⣿⡿⠋⣡⡴⠞⠛⠋⠙⠛⠳⢦⣄⠙⢿⣷⣀⠀⠀⠀⠀⠀⠀",
         "⠀⠀⠈⠙⢿⣿⣿⠟⢠⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⡄⠻⣿⣿⣿⣿⣿⡆⠀",
         "⠀⠀⠀⠀⠈⣿⡟⠀⣾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⡀⢻⣿⣿⣿⣿⣷⠀",
         "⠀⠀⠀⢀⣼⣿⡇⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⢸⣿⡿⠋⠀⠀⠀",
         "⠀⢶⣾⣿⣿⣿⣧⠀⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠁⣸⣿⡀⠀⠀⠀⠀",
         "⠀⠸⣿⣿⣿⣿⣿⣆⠘⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠃⣰⣿⣿⣷⣄⠀⠀⠀",
         "⠀⠀⠉⠀⠀⠀⠙⢿⣷⣌⠛⠶⣤⣀⣀⣀⣀⣤⡴⠛⣡⣾⣿⣿⣿⣿⣿⡟⠀⠀",
         "⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣷⣦⣄⣉⣉⣉⣉⣠⣴⣾⡿⠛⠋⠛⠻⢿⠏⠀⠀⠀",
         "⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⡿⠿⠿⢿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⠀⠀⠀⠀⠀⠈⠛⠿⣿⠏⠀⠀⠀⠀⠙⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀"}

    local button = dashboard.button

    dashboard.section.buttons.val = {button("SPC e k", "  Keyboard Mappings", ":EditKeyMappings <CR>"),
                                     button("SPC e o", "  Set Options", ":EditCustomOptions <CR>"),
                                     button("SPC e d", "舘 Configure Dashboard", ":EditCustomDashboard <CR>"),
                                     button("SPC e p", "  Configure Plugins", ":EditInstalledPlugins <CR>"),
                                     button("SPC e s", "  Vim config", ":e $MYVIMRC | :noautocmd lcd %:p:h <CR>"),
                                     button("q", "  Quit Neovim", ":qa <CR>")}

    local fn = vim.fn
    local marginTop = 0.135
    local headerPadding = fn.max({2, fn.floor(fn.winheight(0) * marginTop)})
    dashboard.config.layout[1].val = headerPadding
    dashboard.config.layout[3].val = 5

    return dashboard
end

return settings_alpha_setup
