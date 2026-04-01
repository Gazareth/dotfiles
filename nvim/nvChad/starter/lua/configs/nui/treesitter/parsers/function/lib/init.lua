local constants = require("configs.nui.treesitter.parsers.function.lib.constants")
local parameters = require("configs.nui.treesitter.parsers.function.lib.parameters")
local method = require("configs.nui.treesitter.parsers.function.lib.method")
local metrics = require("configs.nui.treesitter.parsers.function.lib.metrics")
local targets = require("configs.nui.treesitter.parsers.function.lib.targets")

local M = {}

M = vim.tbl_extend("force", M, constants, parameters, method, metrics, targets)

return M