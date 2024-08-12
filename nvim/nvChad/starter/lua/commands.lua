local acmd = vim.api.nvim_create_autocmd
local ucmd = vim.api.nvim_create_autocmd

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
  callback = close_empty_buffers
})

-- Highlight yanked text for a brief period after yanking
acmd({ "TextYankPost" }, {
  callback = function()
    vim.highlight.on_yank { higroup = "YankHighlight", timeout = 375 }
  end,
})

local open_config_files = function(left_rel_path, right_rel_path)
  local cfg_root = vim.fn.stdpath('config')
  local left_full_path = vim.fn.expand(cfg_root .. "/" .. left_rel_path)
  local right_full_path = vim.fn.expand(cfg_root .. "/" .. right_rel_path and right_rel_path or "")
  local open_fn = "tabnew"
  if vim.bo.filetype == "alpha" then
    open_fn = "e"
  end
-- vim.print("opening! ".. open_fn.." "..left_full_path .. (right_rel_path and (" | vsp "..right_full_path) or ""))

  vim.cmd(open_fn.." "..left_full_path .. (right_rel_path and (" | vsp "..right_full_path) or ""))
end

local config_commands = {
  ["EditCustomDashboard"] = {
    "lua/custom/plugins/overrides/alpha.lua"
  },
  ["EditKeyMappings"] = {
    "lua/core/mappings.lua", "lua/custom/mappings/init.lua"
  },
  ["EditInstalledPlugins"] = {
    "lua/plugins/init.lua", "lua/custom/plugins/init.lua"
  },
  ["EditCustomOptions"] = {
    "lua/core/options.lua", "lua/custom/options.lua"
  },
}

-- Create commands for each entry in `config_commands` above
for k,v in pairs(config_commands) do
  ucmd(k, function()
    open_config_files(v[1], v[2])
  end, {})
end

