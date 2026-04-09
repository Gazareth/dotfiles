local M = {}

M.identifier = require("configs.hydra.atlantis.treesitter.probes.identifier")
M.assignment = require("configs.hydra.atlantis.treesitter.probes.assignment")
M.binary_expression = require("configs.hydra.atlantis.treesitter.probes.binary_expression")
M.fn = require("configs.hydra.atlantis.treesitter.probes.function")
M.parameter = require("configs.hydra.atlantis.treesitter.probes.parameter")
M.generic = require("configs.hydra.atlantis.treesitter.probes.generic")

return M
