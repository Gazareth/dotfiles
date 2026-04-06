local context = require("configs.hydra.treesitter.parsers.identifier.lib.context")
local role = require("configs.hydra.treesitter.parsers.identifier.lib.role")

local M = {}

-- Identifier helper export
M = vim.tbl_extend("force", M, context, role)

return M
