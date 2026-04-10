-- Built-in language mapping tables used by semantic resolution
return {
  core = require("configs.hydra.atlantis.registry.languages.core"),
  common = require("configs.hydra.atlantis.registry.languages.common"),
  base = {
    lua = require("configs.hydra.atlantis.registry.languages.lua"),
  },
}
