
local glob_require = require("custom.functions.globRequire").glob_require

local nvchad = require("custom.plugins.nvchad")
local core = require("custom.plugins.core")
local motions = require("custom.plugins.motions")
local ui = require("custom.plugins.ui")
local autoediting = require("custom.plugins.autoediting")
local cosmetic = require("custom.plugins.cosmetic")

-- Find all files in plugins dir and merge
local all_plugins = glob_require("custom/plugins")

return nvchad