local M = {}

M.identifier = require("configs.hydra.atlantis.treesitter.probes.node_kinds.identifier")
M.assignment = require("configs.hydra.atlantis.treesitter.probes.node_kinds.assignment")
M.binary_expression = require("configs.hydra.atlantis.treesitter.probes.node_kinds.binary_expression")
M.fn = require("configs.hydra.atlantis.treesitter.probes.node_kinds.function")
M.parameter = require("configs.hydra.atlantis.treesitter.probes.node_kinds.parameter")
M.generic = require("configs.hydra.atlantis.treesitter.probes.node_kinds.generic")

return M
