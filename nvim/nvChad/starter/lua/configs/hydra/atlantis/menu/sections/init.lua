-- Aggregates the three menu sections (jump, modify, swap) for external access
local M = {}

M.jump   = require("configs.hydra.atlantis.menu.sections.jump")
M.modify = require("configs.hydra.atlantis.menu.sections.modify")
M.swap   = require("configs.hydra.atlantis.menu.sections.swap")

return M
