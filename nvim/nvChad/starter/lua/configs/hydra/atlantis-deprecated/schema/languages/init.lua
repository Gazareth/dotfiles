-- Built-in language mapping tables used by semantic resolution
return {
  core = require("configs.hydra.atlantis-deprecated.schema.languages.core"),
  common = require("configs.hydra.atlantis-deprecated.schema.languages.common"),
  base = {
    lua = require("configs.hydra.atlantis-deprecated.schema.languages.lua"),
  },
}
