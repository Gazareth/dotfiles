local context = require("configs.nui.treesitter.parsers.identifier.lib.context")
local role = require("configs.nui.treesitter.parsers.identifier.lib.role")

local M = {}

-- Combine identifier helper modules into one export table.
M = vim.tbl_extend("force", M, context, role)

return M