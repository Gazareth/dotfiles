local env_file_present, env = pcall(require, "env")
local nvchad_present, nvchad = pcall(require, "nvchad")

if not env_file_present then
  vim.print("Warning! Env file not detected! Project directories will not be found.")
else
    vim.g.project_patterns = env.project_patterns
end

if not nvchad_present then
  vim.print("Error! NvChad not detected! Are you no longer using it?")
else
    require "nvchad.mappings"
    require "nvchad.options"
end

-- Is windows?
vim.g.is_windows = vim.loop.os_uname().version:match('Windows')

require "neovide"
require "options"
require "commands"
require "mappings"
