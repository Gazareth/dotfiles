local M = {}

M.common = require("configs.hydra.atlantis.ops.common")
M.functions = require("configs.hydra.atlantis.ops.functions")
M.assignments = require("configs.hydra.atlantis.ops.assignments")
M.filter = require("configs.hydra.atlantis.ops.filter")
M.change = require("configs.hydra.atlantis.ops.change")
M.select = require("configs.hydra.atlantis.ops.select")
M.edit = require("configs.hydra.atlantis.ops.edit")
M.swap = require("configs.hydra.atlantis.ops.swap")
M.remove = require("configs.hydra.atlantis.ops.remove")
M.navigate = require("configs.hydra.atlantis.ops.navigate")

return M
