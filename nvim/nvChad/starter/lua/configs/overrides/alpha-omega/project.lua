local base_alpha_setup = function(dashboard)

    dashboard.section.header.val =
        {"⠀⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣄⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⣉⣤⣴⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⣁⣤⣾⣿⣿⣿⣿⣿⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⣿⣿⡿⠟⢁⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀",
         "⠀⣿⣿⣿⣿⡿⠋⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠟⠛⠛⠋⠉⠉⠉⠀⠀⠀⠀",
         "⠀⣿⣿⡿⠋⣠⣾⣿⣿⣿⣿⠿⠟⠛⣉⣥⣤⣴⣶⣶⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⣿⠋⢠⣾⣿⣿⡿⠟⠉⣠⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀",
         "⠀⠁⣴⣿⡿⠛⢁⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀",
         "⠀⣾⠟⠉⣠⣾⣿⣿⣿⣿⣿⣿⠿⠿⠛⠛⢉⣉⣉⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⢁⣴⣿⣿⣿⡿⠟⠋⣉⣠⣤⣶⣶⣾⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀",
         "⠀⠛⠛⠛⠋⠁⠀⠒⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠂⠀⠀⠀⠀⠀⠀⠀"}

    local button = dashboard.button

    dashboard.section.buttons.val = {button("SPC f p", "  Open another Project", ":NeovimProjectHistory<CR>"),
                                     button("SPC f p", "  Open new Project", ":NeovimProjectDiscover<CR>"),
                                     button("SPC f o", "  Recent File  ", ":Telescope oldfiles<CR>"),
                                     button("SPC t e", "  Terminal  ", ":terminal <CR>"),
                                     button("SPC t k", "  Keymap Lookup", ":Telescope keymaps <CR>"),
                                     button("q", "  Quit Neovim", ":qa <CR>")}

    local fn = vim.fn
    local marginTop = 0.135
    local headerPadding = fn.max({2, fn.floor(fn.winheight(0) * marginTop)})
    dashboard.config.layout[1].val = headerPadding
    dashboard.config.layout[3].val = 5

    return dashboard
end

return base_alpha_setup
