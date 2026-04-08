local M = {}

-- Jump column loader
M.jump = require("configs.hydra.atlantis.menu.columns.jump")
-- Modify column loader
M.modify = require("configs.hydra.atlantis.menu.columns.modify")
-- Swap column loader
M.swap = require("configs.hydra.atlantis.menu.columns.swap")

return M
