local acmd = vim.api.nvim_create_autocmd
local ucmd = vim.api.nvim_create_user_command

-- Global command to set current directory to the nvim config dir
ucmd("CdHome", function()
    -- local Switcher = require("projections.switcher")
    -- Switcher:set_current()
    vim.cmd("cd " .. vim.fn.stdpath('config'))
end, {})

-- GENERAL AUTOCMDS
-- Set cd to neovim config on start (if alpha is the only open buffer)
acmd({"VimEnter"}, {
    callback = function()
        local current_type = vim.bo.filetype
        if current_type == "alpha" or #current_type == 0 then
            vim.schedule(function()
                vim.cmd("CdHome")
            end)
        end
    end
})

-- Highlight yanked text for a brief period after yanking
acmd({"TextYankPost"}, {
    callback = function()
        vim.highlight.on_yank {
            higroup = "YankHighlight",
            timeout = 375
        }
    end
})

-- Custom commands to open various config files
local open_config_file = function(rel_path)
    local cfg_root = vim.fn.stdpath('config')
    local full_path = vim.fn.expand(cfg_root .. "/" .. rel_path)
    local open_fn = "tabnew"
    if vim.bo.filetype == "alpha" then
        open_fn = "e"
    end

    vim.cmd(open_fn .. " " .. full_path)
end

local config_commands = {
    ["EditCustomDashboard"] = "lua/plugins/overrides/alpha.lua",
    ["EditKeyMappings"] = "lua/mappings/init.lua",
    ["EditInstalledPlugins"] = "lua/plugins/init.lua",
    ["EditCustomOptions"] = "lua/options.lua"
}

for k, v in pairs(config_commands) do
    ucmd(k, function()
        open_config_file(v)
    end, {})
end

-- Autocmd to open Alpha when last buffer is closed
acmd("BufDelete", {
    group = vim.api.nvim_create_augroup("bufdelpost_autocmd", {}),
    desc = "BufDeletePost User autocmd",
    callback = function()
        vim.schedule(function()
            vim.api.nvim_exec_autocmds("User", {
                pattern = "BufDeletePost"
            })
        end)
    end
})

acmd("User", {
    pattern = "BufDeletePost",
    group = vim.api.nvim_create_augroup("dashboard_delete_buffers", {}),
    desc = "Open Dashboard when no available buffers",
    callback = function(ev)
        local deleted_name = vim.api.nvim_buf_get_name(ev.buf)
        local deleted_ft = vim.api.nvim_get_option_value("filetype", {
            buf = ev.buf
        })
        local deleted_bt = vim.api.nvim_get_option_value("buftype", {
            buf = ev.buf
        })
        local dashboard_on_empty = deleted_name == "" and deleted_ft == "" and deleted_bt == ""

        if dashboard_on_empty then
            vim.cmd("Alpha")
        end
    end
})
