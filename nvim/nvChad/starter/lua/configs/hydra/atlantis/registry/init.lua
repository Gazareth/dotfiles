local M = {}

M.node_tiers = require("configs.hydra.atlantis.anchor.registry.kinds")
M.node_actions = require("configs.hydra.atlantis.anchor.registry.actions")
M.node_capabilities = require("configs.hydra.atlantis.registry.node_capabilities")
M.resolver = require("configs.hydra.atlantis.anchor.probe.resolver")

return M
