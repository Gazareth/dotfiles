local acmd = vim.api.nvim_create_autocmd
local ucmd = vim.api.nvim_create_user_command

local close_empty_buffers = require("functions.buffers").close_empty_buffers

-- Global command to set current directory to the nvim config dir
ucmd("CdHome", function()
  -- local Switcher = require("projections.switcher")
  -- Switcher:set_current()
  vim.cmd("cd "..vim.fn.stdpath('config'))
end, {})

-- GENERAL AUTOCMDS
-- Set cd to neovim config on start (if alpha is the only open buffer)
acmd({ "VimEnter" }, {
  callback = function()
    local current_type = vim.bo.filetype
    if current_type == "alpha" or #current_type == 0 then
      vim.schedule(function() vim.cmd("CdHome") end)
    end
  end,
})

-- Close empty buffers when left
acmd({ "BufLeave" }, {
  callback = function () vim.schedule(close_empty_buffers) end
})

-- Highlight yanked text for a brief period after yanking
acmd({ "TextYankPost" }, {
  callback = function()
    vim.highlight.on_yank { higroup = "YankHighlight", timeout = 375 }
  end,
})

local open_config_file = function(rel_path)
  local cfg_root = vim.fn.stdpath('config')
  local full_path = vim.fn.expand(cfg_root .. "/" .. rel_path)
  local open_fn = "tabnew"
  if vim.bo.filetype == "alpha" then
    open_fn = "e"
  end

  vim.cmd(open_fn.." "..full_path)
end

local config_commands = {
  ["EditCustomDashboard"] = "lua/plugins/overrides/alpha.lua",
  ["EditKeyMappings"] = "lua/mappings/init.lua",
  ["EditInstalledPlugins"] = "lua/plugins/init.lua",
  ["EditCustomOptions"] = "lua/options.lua",
}

-- Create commands for each entry in `config_commands` above
for k,v in pairs(config_commands) do
  ucmd(k, function()
    open_config_file(v)
  end, {})
end

