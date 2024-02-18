local env_file_present, env = pcall(require, "custom.env")

if not env_file_present then
  vim.print("Warning! Env file not detected! Project directories will not be found.")
else
    vim.g.project_patterns = env.project_patterns
end


-- Is windows?
vim.g.is_windows = vim.loop.os_uname().version:match('Windows')

require "custom.neovide"
require "custom.commands"
require "custom.options"
