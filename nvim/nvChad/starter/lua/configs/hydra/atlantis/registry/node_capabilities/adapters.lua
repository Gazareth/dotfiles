-- Node capability adapter registry by semantic node kind
local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

return {
  [supported_nodes.parameter] = {
    factory = "configs.hydra.atlantis.ops.actions.specific.parameter.sibling",
    subadapters = {
      "configs.hydra.atlantis.node_capabilities.adapters.parameter.core",
      "configs.hydra.atlantis.node_capabilities.adapters.parameter.sibling",
    },
  },
}
