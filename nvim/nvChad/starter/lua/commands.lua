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

-- Populate workspace diagnostics
ucmd("WkspDiag", function()
    local any_triggered = false

    for _, client in ipairs(vim.lsp.get_clients()) do
        local has_openclose = client:supports_method("textDocumentSync/openClose")
        local has_publish = client:supports_method("textDocument/publishDiagnostics")
        local has_filetypes = client.config and client.config.filetypes

        if not has_openclose or not has_publish or not has_filetypes then
            vim.notify(string.format("WkspDiag skipped %s: openClose=%s publishDiagnostics=%s filetypes=%s",
                client.name, tostring(has_openclose), tostring(has_publish), vim.inspect(has_filetypes)),
                vim.log.levels.WARN)
        else
            require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
            vim.notify("WkspDiag triggered for " .. client.name, vim.log.levels.INFO)
            any_triggered = true
        end
    end

    if not any_triggered then
        vim.notify("WkspDiag: no eligible LSP clients found", vim.log.levels.ERROR)
    end

local path = "/full/path/to/nvim/nvChad/starter/lua/configs/test.lua"
local uri = vim.uri_from_fname(path)
local bufnr = vim.uri_to_bufnr(uri)
print(vim.inspect(vim.diagnostic.get(bufnr)))

end, {})

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

-- Open dashboard when last buffer is closed
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

-- Open dashboard when no available buffers
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
