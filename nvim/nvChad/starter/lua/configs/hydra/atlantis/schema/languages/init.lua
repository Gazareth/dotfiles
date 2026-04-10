-- Built-in language mapping tables used by semantic resolution
return {
  core = require("configs.hydra.atlantis.schema.languages.core"),
  common = require("configs.hydra.atlantis.schema.languages.common"),
  base = {
    lua = require("configs.hydra.atlantis.schema.languages.lua"),
  },
}
