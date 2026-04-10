local constants = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.constants")
local parameters = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.parameters")
local method = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.method")
local metrics = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.metrics")
local targets = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.targets")

local M = {}

M = vim.tbl_extend("force", M, constants, parameters, method, metrics, targets)

return M
