-- Is windows?
vim.g.is_windows = vim.loop.os_uname().version:match('Windows')

require "custom.neovide"
require "custom.commands"
require "custom.options"
