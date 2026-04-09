-- Aggregates action component modules for external access
local M = {}

M.registry = require("configs.hydra.atlantis.menu.components.action.registry")
M.rows     = require("configs.hydra.atlantis.menu.components.action.rows")
M.filter   = require("configs.hydra.atlantis.menu.components.action.filter")

return M
