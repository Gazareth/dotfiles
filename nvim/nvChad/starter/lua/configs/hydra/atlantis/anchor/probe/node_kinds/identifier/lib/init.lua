local context = require("configs.hydra.atlantis.anchor.probe.node_kinds.identifier.lib.context")
local role = require("configs.hydra.atlantis.anchor.probe.node_kinds.identifier.lib.role")

local M = {}

-- Identifier helper export
M = vim.tbl_extend("force", M, context, role)

return M
